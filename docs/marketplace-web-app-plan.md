# Resal Marketplace Web Application — Implementation Plan

> **Status:** Draft · **Date:** April 2, 2026 · **Author:** Resal Engineering

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Architecture Overview](#2-architecture-overview)
- [3. Technology Decisions](#3-technology-decisions)
- [4. Data Model](#4-data-model)
- [5. API Design](#5-api-design)
- [6. Frontend Design](#6-frontend-design)
- [7. Git Sync Engine](#7-git-sync-engine)
- [8. Authentication & Authorization](#8-authentication--authorization)
- [9. Docker & Deployment](#9-docker--deployment)
- [10. Project Structure](#10-project-structure)
- [11. Implementation Phases](#11-implementation-phases)
- [12. Testing Strategy](#12-testing-strategy)
- [13. Risks & Mitigations](#13-risks--mitigations)

---

## 1. Executive Summary

### Problem

The Resal Marketplace is a Git-based repository of Claude Code plugins and skills. Today, discovering, browsing, and contributing plugins requires directly interacting with GitHub — reading `marketplace.json`, navigating folder structures, and manually creating PRs.

### Solution

A **self-hosted web application** that provides:

| Capability | Description |
|---|---|
| **Browse** | Visual catalog of all plugins and their skills, with rich documentation rendering |
| **Search** | Full-text search across plugin names, descriptions, skills, and reference docs |
| **Detail Pages** | Rendered SKILL.md, references, plugin metadata, and version info per plugin |
| **Push** | API + UI to submit new plugins/skills, creating a Git branch + PR for review |

### Scope

- **Users:** Internal Resal engineering team (~10-50 developers)
- **MVP includes:** All four capabilities above (browse, search, detail, push)
- **Out of scope (v1):** Plugin versioning history, user ratings/comments, automated plugin testing, webhook-based real-time sync

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Docker Network                        │
│                                                         │
│  ┌──────────────────┐      ┌────────────────────────┐  │
│  │   Frontend        │      │   Backend API           │  │
│  │   React + Vite    │─────▶│   Express.js            │  │
│  │   Shadcn/Tailwind │      │   REST API              │  │
│  │   :3000           │      │   :4000                 │  │
│  └──────────────────┘      └──────────┬─────────────┘  │
│                                       │                 │
│                              ┌────────┴─────────┐      │
│                              │                  │      │
│                       ┌──────▼──────┐  ┌───────▼──────┐│
│                       │   SQLite     │  │  GitHub API  ││
│                       │   + FTS5     │  │  (Octokit)   ││
│                       │   metadata   │  │  read/PR     ││
│                       │   + search   │  │              ││
│                       └─────────────┘  └──────────────┘│
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Data Flow

```
GitHub Repo (source of truth)
    │
    ├── READ: GitHub API fetches marketplace.json + plugin files
    │         Backend parses & indexes into SQLite
    │
    └── WRITE: User submits plugin via UI
              → Backend validates payload
              → Creates Git branch via GitHub API
              → Opens PR with marketplace.json + file changes
              → PR reviewed & merged
              → Sync job re-indexes after merge
```

---

## 3. Technology Decisions

| Layer | Technology | Rationale |
|---|---|---|
| **Frontend** | React 19 + Vite 6 | Fast dev server, modern DX, tree-shaking |
| **UI Components** | Shadcn/ui + Tailwind CSS 4 | Accessible, professional, customizable, great for data-heavy UIs |
| **Backend** | Express.js 5 | Mature ecosystem, lightweight, well-understood by team |
| **API Style** | REST | Simple CRUD mapping, easy to consume |
| **Database** | SQLite + FTS5 | Zero-config, file-based, perfect for internal apps, built-in full-text search |
| **ORM** | Drizzle ORM | Type-safe, lightweight, excellent SQLite support |
| **Git Sync** | Octokit (GitHub REST API) | No local clone needed, direct API for reading files and creating PRs |
| **Auth** | Microsoft Entra ID (Azure AD) | SSO with existing Microsoft setup, enterprise-grade |
| **Search** | SQLite FTS5 | Built-in, sufficient for internal scale |
| **Containerization** | Docker + docker-compose | Consistent deployment, matches existing Resal infra patterns |
| **Language** | TypeScript (both frontend + backend) | Type safety, shared types, better DX |

---

## 4. Data Model

### 4.1 Entities

```sql
-- Synced from GitHub repo. Re-indexed on webhook or scheduled poll.
CREATE TABLE plugins (
  id            TEXT PRIMARY KEY,           -- e.g. "add-app-deployment"
  name          TEXT NOT NULL,
  description   TEXT NOT NULL,
  version       TEXT,                        -- from plugin.json
  author_name   TEXT,
  source_path   TEXT NOT NULL,               -- "./plugins/add-app-deployment" or external source
  source_type   TEXT NOT NULL DEFAULT 'local', -- 'local' | 'github'
  source_repo   TEXT,                        -- for external plugins, e.g. "ResalApps/AI_Workflow"
  source_subpath TEXT,                       -- e.g. "resal-pm-plugin"
  keywords      TEXT,                        -- JSON array of keywords
  indexed_at    TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE skills (
  id            TEXT PRIMARY KEY,           -- e.g. "add-app-deployment" (matches skill folder)
  plugin_id     TEXT NOT NULL REFERENCES plugins(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT NOT NULL,              -- from SKILL.md frontmatter
  skill_md      TEXT NOT NULL,              -- full SKILL.md content (rendered in detail view)
  skill_order   INTEGER DEFAULT 0,
  indexed_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE references (
  id            TEXT PRIMARY KEY,           -- e.g. "add-app-deployment/helm-templates"
  skill_id      TEXT NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  filename      TEXT NOT NULL,
  content       TEXT NOT NULL,              -- full markdown content
  file_order    INTEGER DEFAULT 0
);

-- Full-text search virtual table
CREATE VIRTUAL TABLE plugins_fts USING fts5(
  plugin_id,
  name,
  description,
  keywords,
  skill_descriptions,     -- aggregated skill descriptions
  reference_content,      -- aggregated reference content
  content=''
);

-- Categories/tags for filtering
CREATE TABLE tags (
  id            TEXT PRIMARY KEY,           -- e.g. "deployment", "infrastructure"
  label         TEXT NOT NULL,
  color         TEXT                        -- hex color for UI badges
);

CREATE TABLE plugin_tags (
  plugin_id     TEXT REFERENCES plugins(id) ON DELETE CASCADE,
  tag_id        TEXT REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (plugin_id, tag_id)
);

-- Tracks sync state
CREATE TABLE sync_state (
  id            INTEGER PRIMARY KEY CHECK (id = 1), -- singleton
  last_commit_sha TEXT,
  last_sync_at    TEXT NOT NULL DEFAULT (datetime('now')),
  sync_status     TEXT DEFAULT 'idle'       -- 'idle' | 'syncing' | 'error'
);
```

### 4.2 Entity Relationships

```
Plugin 1──* Skill 1──* Reference
Plugin *──* Tag
```

### 4.3 Sync Strategy

The backend maintains a **mirror** of the repo metadata in SQLite for fast queries. The source of truth is always the Git repo.

| Trigger | Action |
|---|---|
| **Startup** | Fetch `marketplace.json` + all plugin files via GitHub API, rebuild DB |
| **Scheduled** (every 5 min) | Poll for new commits on `master`. If new SHA, re-index |
| **Manual** | Admin endpoint `POST /api/admin/sync` triggers immediate re-index |
| **Post-merge** (future) | GitHub webhook triggers sync after PR merge |

---

## 5. API Design

### 5.1 Base URL

```
/api
```

### 5.2 Endpoints

#### Plugins — Browse & Search

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/plugins` | List all plugins with optional filtering & pagination |
| `GET` | `/plugins/:id` | Get plugin detail (metadata + skills list) |
| `GET` | `/plugins/:id/readme` | Get the rendered plugin SKILL.md content |
| `GET` | `/search?q=&tag=&page=&limit=` | Full-text search across plugins, skills, references |

**Query Parameters for `GET /plugins`:**
```
?tag=deployment          # filter by tag
?keyword=helm            # filter by keyword
?page=1&limit=20         # pagination
?sort=updated_at         # sort field
?order=desc              # sort direction
```

**Response shape — `GET /plugins`:**
```json
{
  "data": [
    {
      "id": "add-app-deployment",
      "name": "resal-deployment",
      "description": "Add deployment pipeline support...",
      "version": "1.0.0",
      "author": "Resal DevOps",
      "keywords": ["deployment", "infrastructure", "helm"],
      "tags": [
        { "id": "deployment", "label": "Deployment", "color": "#3B82F6" }
      ],
      "skills": [
        { "id": "add-app-deployment", "name": "add-app-deployment", "description": "..." }
      ],
      "updated_at": "2026-03-28T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 2,
    "pages": 1
  }
}
```

#### Skills — Detail & Documentation

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/plugins/:pluginId/skills` | List skills for a plugin |
| `GET` | `/plugins/:pluginId/skills/:skillId` | Get skill detail with full SKILL.md |
| `GET` | `/plugins/:pluginId/skills/:skillId/references` | List references for a skill |
| `GET` | `/plugins/:pluginId/skills/:skillId/references/:refId` | Get single reference doc content |

#### Plugin Submission — Push

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/submissions` | Submit a new plugin or skill (creates branch + PR) |
| `GET` | `/submissions` | List user's submissions (PRs) |
| `GET` | `/submissions/:id` | Get submission status |

**`POST /submissions` payload:**
```json
{
  "type": "plugin",
  "plugin": {
    "name": "my-new-plugin",
    "description": "What the plugin does",
    "version": "1.0.0",
    "author": "Engineer Name",
    "keywords": ["monitoring", "alerts"]
  },
  "skills": [
    {
      "name": "my-skill",
      "description": "When to trigger this skill",
      "skill_md": "# My Skill\n\nFull SKILL.md content here...",
      "references": [
        {
          "filename": "setup-guide.md",
          "content": "# Setup Guide\n\n..."
        }
      ]
    }
  ],
  "tags": ["monitoring"],
  "commit_message": "Add my-new-plugin to marketplace"
}
```

**Response (202 Accepted):**
```json
{
  "id": "sub_abc123",
  "status": "pr_created",
  "pr_url": "https://github.com/ResalApps/resal-marketplace/pull/42",
  "branch": "plugin/my-new-plugin-20260402",
  "message": "PR created for review. Plugin will appear in marketplace after merge."
}
```

#### Admin

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/admin/sync` | Trigger manual re-index from GitHub |
| `GET` | `/admin/sync/status` | Get current sync state |
| `GET` | `/admin/stats` | Get marketplace stats (plugin count, skill count, etc.) |

#### Auth

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/auth/login` | Redirect to Entra ID login |
| `GET` | `/auth/callback` | Entra ID OAuth callback |
| `POST` | `/auth/logout` | Clear session |
| `GET` | `/auth/me` | Get current user profile |

---

## 6. Frontend Design

### 6.1 Pages & Routes

| Route | Page | Description |
|---|---|---|
| `/` | **Marketplace Home** | Hero section + featured plugins grid + search bar |
| `/plugins` | **Plugin Catalog** | Full grid/list of all plugins with search & filters sidebar |
| `/plugins/:id` | **Plugin Detail** | Plugin overview, metadata, skills list, documentation tabs |
| `/plugins/:id/skills/:skillId` | **Skill Detail** | Rendered SKILL.md + reference docs sidebar navigation |
| `/submit` | **Submit Plugin** | Multi-step form to push a new plugin/skill |
| `/submissions` | **My Submissions** | List of user's PRs with status |
| `/login` | **Login** | Entra ID auth redirect |

### 6.2 Component Tree

```
App
├── Layout
│   ├── Header
│   │   ├── Logo + Title
│   │   ├── SearchBar (global)
│   │   └── UserMenu (avatar, logout)
│   ├── Sidebar (on detail pages)
│   │   └── Navigation / Filters
│   └── Footer
│
├── Pages
│   ├── HomePage
│   │   ├── HeroBanner
│   │   ├── SearchBar (prominent)
│   │   ├── PluginGrid (featured)
│   │   └── QuickCategories (tags)
│   │
│   ├── CatalogPage
│   │   ├── SearchAndFilterBar
│   │   │   ├── SearchInput
│   │   │   ├── TagFilterChips
│   │   │   └── SortDropdown
│   │   ├── PluginGrid
│   │   │   └── PluginCard (name, desc, tags, skill count)
│   │   └── Pagination
│   │
│   ├── PluginDetailPage
│   │   ├── PluginHeader (name, version, author, tags)
│   │   ├── TabLayout
│   │   │   ├── OverviewTab (description, keywords)
│   │   │   ├── SkillsTab (list of skills with descriptions)
│   │   │   └── MetadataTab (plugin.json raw, source info)
│   │   └── RelatedPlugins
│   │
│   ├── SkillDetailPage
│   │   ├── SkillHeader (name, plugin breadcrumb)
│   │   ├── MarkdownRenderer (SKILL.md)
│   │   └── ReferencesSidebar
│   │       └── ReferenceLink → renders in main panel
│   │
│   └── SubmitPage
│       ├── StepIndicator
│       ├── Step1_PluginInfo (name, description, version, keywords)
│       ├── Step2_SkillEditor
│       │   ├── SkillMetadataForm
│       │   ├── MarkdownEditor (SKILL.md content)
│       │   └── ReferenceUploader
│       ├── Step3_Review (preview all data before submit)
│       └── Step4_Submitted (PR link, next steps)
```

### 6.3 Key UI Decisions

| Element | Decision |
|---|---|
| **Markdown rendering** | `react-markdown` + `rehype-highlight` for syntax highlighting in SKILL.md and references |
| **Markdown editor** | `@uiw/react-md-editor` for the submit form (split preview) |
| **Search** | Debounced search input (300ms) with instant results via SQLite FTS5 |
| **Plugin cards** | Card grid (3 columns desktop, 1 mobile) with tag chips and skill count badge |
| **Breadcrumbs** | `Marketplace > Plugin Name > Skill Name` for navigation context |
| **Theme** | Light mode default, dark mode toggle (Resal brand colors via Tailwind config) |
| **Responsive** | Mobile-first, collapsible sidebar, stacked cards on small screens |

---

## 7. Git Sync Engine

### 7.1 Read Sync (GitHub → SQLite)

```
┌─────────────┐    ┌──────────────────┐    ┌──────────┐
│ GitHub API   │───▶│ SyncService      │───▶│ SQLite   │
│ (Octokit)    │    │ parse + index    │    │ DB       │
└─────────────┘    └──────────────────┘    └──────────┘
```

**Algorithm:**

1. Fetch `.claude-plugin/marketplace.json` from `master` branch
2. For each plugin entry in `plugins[]`:
   - If `source` is a string (local path): fetch `plugin.json` from that path
   - If `source` is an object (external repo): fetch from the external repo/path
3. For each plugin, list `skills/*/SKILL.md` files
4. For each skill, parse frontmatter (name, description) and store full content
5. For each skill, list and fetch `references/*.md` files
6. Extract keywords from `plugin.json`, categorize into tags
7. Rebuild `plugins_fts` with aggregated content
8. Update `sync_state` with latest commit SHA

### 7.2 Write Sync (UI → GitHub PR)

```
┌────────────┐    ┌───────────────────┐    ┌─────────────┐
│ Submission  │───▶│ SubmissionService │───▶│ GitHub PR   │
│ API         │    │ validate + push   │    │ (review)    │
└────────────┘    └───────────────────┘    └─────────────┘
```

**Algorithm:**

1. **Validate** the submission payload (required fields, name format, no duplicates)
2. **Check** if plugin name already exists in `marketplace.json`
3. **Create branch** `plugin/{name}-{date}` on `ResalApps/resal-marketplace`
4. **Write files** via GitHub API:
   - `plugins/{name}/.claude-plugin/plugin.json`
   - `plugins/{name}/skills/{skill}/SKILL.md`
   - `plugins/{name}/skills/{skill}/references/*.md` (if any)
   - Update `.claude-plugin/marketplace.json` with new entry
   - Update `docs/README.md` plugin table with new row
   - Create `docs/{name}.md` documentation stub
5. **Open PR** with title `feat: add {name} plugin to marketplace`
6. **Return** PR URL to the user

### 7.3 File Templates for New Plugins

The submission engine will generate these files:

**`plugin.json`:**
```json
{
  "name": "{name}",
  "description": "{description}",
  "version": "{version}",
  "author": {
    "name": "{author}"
  },
  "keywords": {keywords}
}
```

**`SKILL.md`:**
```markdown
---
name: {skill_name}
description: {skill_description}
---

{skill_md_content}
```

**marketplace.json entry:**
```json
{
  "name": "{name}",
  "source": "./plugins/{name}",
  "description": "{description}"
}
```

---

## 8. Authentication & Authorization

### 8.1 Entra ID (Azure AD) OAuth 2.0 Flow

```
User → Browser → /auth/login
    → Redirect to Entra ID authorize endpoint
    → User authenticates (SSO)
    → Callback with authorization code
    → Backend exchanges code for token
    → Create session (cookie-based)
    → Redirect to marketplace
```

### 8.2 Implementation

- **Strategy:** `@azure/msal-node` on backend, `@azure/msal-browser` on frontend
- **Session:** HTTP-only secure cookies with session tokens
- **Token storage:** In-memory on frontend, session store on backend

### 8.3 Roles

| Role | Permissions |
|---|---|
| **Viewer** (default) | Browse plugins, read docs, search |
| **Contributor** | Submit new plugins (creates PR) |
| **Admin** | Trigger manual sync, manage tags, view stats |

> For MVP, all authenticated users get **Contributor** role. Admin can be role-based via Entra ID group membership.

---

## 9. Docker & Deployment

### 9.1 Dockerfile Strategy

```dockerfile
# Multi-stage build
# Stage 1: Build frontend (Vite)
# Stage 2: Build backend (TypeScript → JavaScript)
# Stage 3: Production image (Node.js Alpine + built assets)
```

### 9.2 docker-compose.yml

```yaml
version: "3.9"

services:
  web:
    build: .
    ports:
      - "3000:3000"   # Frontend (served by Express in production)
      - "4000:4000"   # Backend API (dev only, same port in prod)
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
      - AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
      - AZURE_TENANT_ID=${AZURE_TENANT_ID}
      - SESSION_SECRET=${SESSION_SECRET}
      - NODE_ENV=production
      - PORT=4000
    volumes:
      - marketplace-data:/app/data    # SQLite persistence
    restart: unless-stopped

volumes:
  marketplace-data:
```

### 9.3 Production Notes

- Express serves the built Vite frontend as static files
- Single container, single port (4000) in production
- SQLite database persists via Docker volume
- Health check endpoint: `GET /api/health`

---

## 10. Project Structure

```
resal-marketplace-web/
├── docker-compose.yml
├── Dockerfile
├── package.json                    # Root workspace package.json
├── tsconfig.base.json              # Shared TypeScript config
├── .env.example                    # Environment template
│
├── packages/
│   ├── shared/                     # Shared types & utilities
│   │   ├── package.json
│   │   └── src/
│   │       ├── types/
│   │       │   ├── plugin.ts       # Plugin, Skill, Reference interfaces
│   │       │   ├── submission.ts   # Submission payload types
│   │       │   └── api.ts          # API response shapes
│   │       └── constants.ts        # Tags, categories, defaults
│   │
│   ├── server/                     # Express.js backend
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── src/
│   │       ├── index.ts            # Entry point
│   │       ├── app.ts              # Express app setup
│   │       ├── config/
│   │       │   └── env.ts          # Env validation (zod)
│   │       ├── db/
│   │       │   ├── schema.ts       # Drizzle schema
│   │       │   ├── migrate.ts      # Migration runner
│   │       │   └── connection.ts   # SQLite connection
│   │       ├── routes/
│   │       │   ├── plugins.ts      # Plugin CRUD routes
│   │       │   ├── skills.ts       # Skill detail routes
│   │       │   ├── search.ts       # Search route
│   │       │   ├── submissions.ts  # Plugin submission routes
│   │       │   ├── admin.ts        # Admin routes
│   │       │   └── auth.ts        # Auth routes
│   │       ├── services/
│   │       │   ├── sync.service.ts         # GitHub → DB sync
│   │       │   ├── github-read.service.ts  # Read files via GitHub API
│   │       │   ├── github-write.service.ts # Create branches + PRs
│   │       │   ├── search.service.ts       # FTS5 search
│   │       │   └── submission.service.ts   # Orchestrate submissions
│   │       ├── middleware/
│   │       │   ├── auth.ts          # Entra ID auth middleware
│   │       │   ├── error.ts        # Error handling
│   │       │   └── validate.ts     # Request validation (zod)
│   │       └── utils/
│   │           ├── markdown.ts      # Markdown parsing utilities
│   │           └── frontmatter.ts  # YAML frontmatter parser
│   │
│   └── client/                     # React + Vite frontend
│       ├── package.json
│       ├── vite.config.ts
│       ├── tailwind.config.ts
│       ├── index.html
│       └── src/
│           ├── main.tsx
│           ├── App.tsx
│           ├── routes/
│           │   ├── index.tsx         # Route definitions
│           │   ├── layout.tsx        # Root layout
│           │   ├── home.tsx
│           │   ├── catalog.tsx
│           │   ├── plugin-detail.tsx
│           │   ├── skill-detail.tsx
│           │   ├── submit.tsx
│           │   └── submissions.tsx
│           ├── components/
│           │   ├── ui/               # Shadcn/ui components
│           │   ├── layout/
│           │   │   ├── header.tsx
│           │   │   ├── sidebar.tsx
│           │   │   └── footer.tsx
│           │   ├── plugins/
│           │   │   ├── plugin-card.tsx
│           │   │   ├── plugin-grid.tsx
│           │   │   └── plugin-header.tsx
│           │   ├── skills/
│           │   │   ├── skill-list.tsx
│           │   │   └── reference-sidebar.tsx
│           │   ├── search/
│           │   │   ├── search-bar.tsx
│           │   │   ├── filter-chips.tsx
│           │   │   └── search-results.tsx
│           │   ├── submit/
│           │   │   ├── plugin-info-step.tsx
│           │   │   ├── skill-editor-step.tsx
│           │   │   ├── review-step.tsx
│           │   │   └── submitted-step.tsx
│           │   └── common/
│           │       ├── markdown-renderer.tsx
│           │       ├── tag-badge.tsx
│           │       ├── breadcrumb.tsx
│           │       └── pagination.tsx
│           ├── hooks/
│           │   ├── use-plugins.ts
│           │   ├── use-search.ts
│           │   ├── use-submission.ts
│           │   └── use-auth.ts
│           ├── lib/
│           │   ├── api.ts            # API client (fetch wrapper)
│           │   └── auth.ts           # MSAL configuration
│           └── styles/
│               └── globals.css       # Tailwind imports
│
└── scripts/
    ├── sync.ts                       # Standalone sync script
    └── seed-tags.ts                  # Seed default tags
```

---

## 11. Implementation Phases

### Phase 1: Foundation (Week 1)

**Goal:** Backend skeleton, database, and GitHub read sync working.

| # | Task | Deliverable |
|---|---|---|
| 1.1 | Initialize monorepo (npm workspaces) | `package.json`, `tsconfig.base.json` |
| 1.2 | Setup Express server with TypeScript | `packages/server/` with health check |
| 1.3 | Setup SQLite + Drizzle ORM + schema | DB schema, migration, seed script |
| 1.4 | Implement GitHub read service (Octokit) | Fetch marketplace.json + plugin files |
| 1.5 | Implement sync service | Parse + index plugins/skills/references into DB |
| 1.6 | Build plugin CRUD routes | `GET /api/plugins`, `GET /api/plugins/:id` |
| 1.7 | Build skill & reference routes | `GET /api/plugins/:id/skills/*` |
| 1.8 | Build search route (FTS5) | `GET /api/search?q=` |
| 1.9 | Docker setup | `Dockerfile`, `docker-compose.yml` |

### Phase 2: Frontend Core (Week 2)

**Goal:** All read-only pages functional with real data.

| # | Task | Deliverable |
|---|---|---|
| 2.1 | Initialize React + Vite + Tailwind + Shadcn | `packages/client/` scaffold |
| 2.2 | Setup React Router + layout components | Header, sidebar, footer, breadcrumbs |
| 2.3 | Build API client + data hooks | `lib/api.ts`, `use-plugins`, `use-search` |
| 2.4 | Build Home page | Hero + featured plugins grid + search |
| 2.5 | Build Catalog page | Plugin grid + search + filters + pagination |
| 2.6 | Build Plugin Detail page | Tabs: overview, skills, metadata |
| 2.7 | Build Skill Detail page | Markdown renderer + references sidebar |
| 2.8 | Markdown rendering pipeline | `react-markdown` + syntax highlighting |
| 2.9 | Responsive design pass | Mobile layouts, collapsible sidebar |

### Phase 3: Auth & Submission (Week 3)

**Goal:** Authenticated users can submit new plugins via PR.

| # | Task | Deliverable |
|---|---|---|
| 3.1 | Entra ID auth setup (backend) | `@azure/msal-node`, session cookies |
| 3.2 | Entra ID auth setup (frontend) | Login redirect, auth hooks, protected routes |
| 3.3 | Submission validation service | Validate payload, check duplicates |
| 3.4 | GitHub write service (Octokit) | Create branch, write files, open PR |
| 3.5 | Submission API route | `POST /api/submissions` |
| 3.6 | Submit page (multi-step form) | Plugin info → Skill editor → Review → Submitted |
| 3.7 | My Submissions page | List user's PRs with status |
| 3.8 | Admin endpoints | `POST /api/admin/sync`, `GET /api/admin/stats` |

### Phase 4: Polish & Deploy (Week 4)

**Goal:** Production-ready, well-tested, documented.

| # | Task | Deliverable |
|---|---|---|
| 4.1 | Error handling & loading states | Toast notifications, error boundaries, skeletons |
| 4.2 | Dark mode support | Tailwind dark theme, toggle |
| 4.3 | SEO & meta tags | Open Graph, page titles, descriptions |
| 4.4 | Integration tests | Backend API tests with SQLite |
| 4.5 | E2E tests (Playwright) | Key user flows (browse, search, submit) |
| 4.6 | Production Docker build | Optimized multi-stage build |
| 4.7 | Documentation | README, setup guide, API docs |
| 4.8 | CI/CD pipeline | GitHub Actions for build + test + deploy |

---

## 12. Testing Strategy

### 12.1 Backend Tests

| Type | Tool | Scope |
|---|---|---|
| Unit | Vitest | Services (sync, search, submission, GitHub read/write) |
| Integration | Vitest + supertest | API routes with real SQLite DB |
| Snapshot | Vitest | GitHub API response parsing |

### 12.2 Frontend Tests

| Type | Tool | Scope |
|---|---|---|
| Component | Vitest + Testing Library | UI components, forms |
| Integration | Vitest + msw | Hooks with mocked API |
| E2E | Playwright | Full user flows |

### 12.3 Test Database Strategy

- Use `:memory:` SQLite for tests
- Seed with fixture data matching the real `marketplace.json`
- Mock GitHub API responses with nock or msw

---

## 13. Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| **GitHub API rate limits** | Sync fails during heavy usage | Medium | Cache aggressively, use conditional requests (ETag/If-Modified-Since), schedule sync in off-peak |
| **Large SKILL.md files** | Slow search indexing, large DB | Low | FTS5 handles this well at internal scale; cap content at 500KB per file |
| **Markdown rendering edge cases** | Broken skill doc pages | Medium | Use battle-tested `react-markdown` + fallback to raw text |
| **Entra ID setup complexity** | Blocks auth development | Medium | Start with a simple API key auth as fallback, swap to Entra ID when configured |
| **External plugin sources** | External repos may be unavailable | Low | Graceful degradation — show cached data, mark as "source unavailable" |
| **PR merge conflicts** | Simultaneous submissions conflict | Low | Branch from latest `master`, include merge instructions in PR description |

---

## Appendix A: Environment Variables

```env
# GitHub
GITHUB_TOKEN=ghp_xxxxxxxxxxxx                # PAT with repo access
GITHUB_REPO_OWNER=ResalApps
GITHUB_REPO_NAME=resal-marketplace
GITHUB_DEFAULT_BRANCH=master

# Azure Entra ID
AZURE_CLIENT_ID=
AZURE_CLIENT_SECRET=
AZURE_TENANT_ID=
AZURE_REDIRECT_URI=http://localhost:4000/api/auth/callback

# App
NODE_ENV=development
PORT=4000
SESSION_SECRET=random-32-char-string

# Database
DB_PATH=./data/marketplace.db

# Sync
SYNC_INTERVAL_MS=300000    # 5 minutes
```

## Appendix B: Key Dependencies

### Backend
| Package | Purpose |
|---|---|
| `express` | HTTP server |
| `drizzle-orm` | Type-safe SQLite ORM |
| `better-sqlite3` | SQLite driver |
| `octokit` | GitHub API client |
| `@azure/msal-node` | Entra ID authentication |
| `zod` | Runtime validation |
| `gray-matter` | YAML frontmatter parsing |
| `express-session` | Session management |
| `cors` | CORS middleware |
| `helmet` | Security headers |
| `winston` | Logging |
| `vitest` | Testing |

### Frontend
| Package | Purpose |
|---|---|
| `react` + `react-dom` | UI framework |
| `react-router` | Client-side routing |
| `@tanstack/react-query` | Server state management |
| `tailwindcss` | Utility CSS |
| `@shadcn/ui` components | UI component library |
| `react-markdown` + `rehype-highlight` | Markdown rendering |
| `@uiw/react-md-editor` | Markdown editor for submissions |
| `lucide-react` | Icons |
| `@azure/msal-browser` | Entra ID client auth |
| `sonner` | Toast notifications |
