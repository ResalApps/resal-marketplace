# Implementation Plan: Marketplace Web Application

**Branch**: `001-marketplace-web-app` | **Date**: 2026-04-02 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-marketplace-web-app/spec.md`

## Summary

Build a self-hosted web application for the Resal Marketplace — a Git-based repository of Claude Code plugins. The app provides a browsable catalog of plugins with full-text search, detailed plugin/skill/reference documentation views, a submission workflow for adding new plugins via GitHub PRs, and an admin dashboard for sync management.

**Technical approach**: TypeScript full-stack monorepo (npm workspaces) with Express.js 5 backend, React 19 + Vite 6 frontend, SQLite + FTS5 for storage and search, Drizzle ORM for type-safe database access, Octokit for GitHub API integration, and Microsoft Entra ID SSO for authentication. Docker single-container deployment.

## Technical Context

**Language/Version**: TypeScript 5.8, Node.js 22 LTS
**Primary Dependencies**: Express.js 5, React 19, Vite 6, Drizzle ORM, TanStack Query 5, Shadcn/ui, Tailwind CSS 4, Octokit, @azure/msal-node + @azure/msal-browser
**Storage**: SQLite with FTS5 extension (single-file database, persisted via Docker volume)
**Testing**: Vitest (unit + integration), Supertest (API integration), Playwright (E2E)
**Target Platform**: Docker container (Linux amd64/arm64), accessible via web browser
**Project Type**: Web application (SPA + REST API)
**Performance Goals**: < 200ms p95 API response time, < 2s initial page load, search results in < 500ms
**Constraints**: Self-hosted, single-container, offline-capable browsing, GitHub API rate limit awareness (5,000 req/hr)
**Scale/Scope**: 10–50 daily users, ~100 plugins, ~500 skills, ~2,000 reference documents

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| Clean Code Architecture | ✅ PASS | Layered: Domain (Drizzle schema) → Application (services) → Infrastructure (GitHub API, SQLite) → Presentation (Express routes) → Frontend (React components) |
| DRY | ✅ PASS | Shared types in `packages/shared`, reusable UI components via Shadcn/ui |
| KISS (max 4 projects) | ✅ PASS | 3 packages: shared, server, client |
| Test-First | ✅ PASS | Vitest + Playwright testing strategy defined |
| Reusable UI (Shadcn/ui) | ✅ PASS | Shadcn/ui with Tailwind CSS 4 |
| Server-Side Data Operations | ✅ PASS | All data operations in Express.js services, SQLite for storage |
| Documentation as Code | ✅ PASS | API contracts in `contracts/`, data model in `data-model.md` |
| **Backend: .NET 10/ASP.NET Core** | ⚠️ OVERRIDE | Using TypeScript/Express.js 5 instead (see research.md R-001) |
| **ORM: EF Core** | ⚠️ OVERRIDE | Using Drizzle ORM instead (see research.md R-002) |
| **Testing: xUnit + NSubstitute** | ⚠️ OVERRIDE | Using Vitest + Supertest instead (see research.md R-004) |

**Gate Result**: PASS WITH JUSTIFIED OVERRIDES. The .NET/C# technology choices from the constitution are overridden for this project because: (1) the marketplace is a Node.js ecosystem, (2) TypeScript across the full stack enables shared types and better DX, (3) the original user plan specified Express.js. Architectural principles (layered architecture, DI pattern, testability) are maintained in TypeScript idioms.

## Project Structure

### Documentation (this feature)

```text
specs/001-marketplace-web-app/
├── plan.md              # This file
├── research.md          # Phase 0: technology decisions and rationale
├── data-model.md        # Phase 1: entity definitions, DDL, relationships
├── quickstart.md        # Phase 1: developer setup guide
├── contracts/           # Phase 1: API contract definitions
│   ├── plugins-api.md                  # Plugin catalog endpoints
│   └── search-submissions-admin-auth-api.md  # Search, submissions, admin, auth
└── tasks.md             # Phase 2 (created by /speckit.tasks)
```

### Source Code (repository root)

```text
resal-marketplace/
├── packages/
│   ├── shared/                    # Shared TypeScript types
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── src/
│   │       └── types.ts           # API request/response types
│   ├── server/                    # Express.js backend
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   ├── vite.config.ts
│   │   └── src/
│   │       ├── index.ts           # Entry point
│   │       ├── routes/            # API route handlers
│   │       │   ├── plugins.ts
│   │       │   ├── search.ts
│   │       │   ├── submissions.ts
│   │       │   ├── admin.ts
│   │       │   └── auth.ts
│   │       ├── services/          # Business logic
│   │       │   ├── sync.ts        # GitHub sync engine
│   │       │   ├── submissions.ts # Submission workflow
│   │       │   └── auth.ts        # Entra ID auth
│   │       ├── db/                # Drizzle ORM
│   │       │   ├── schema.ts      # Table definitions
│   │       │   └── migrations/    # SQL migration files
│   │       └── middleware/        # Auth, error handling
│   └── client/                    # React frontend
│       ├── package.json
│       ├── tsconfig.json
│       ├── vite.config.ts
│       ├── index.html
│       └── src/
│           ├── main.tsx           # React entry point
│           ├── App.tsx            # Root with router
│           ├── pages/
│           │   ├── Catalog.tsx    # Browse plugins
│           │   ├── PluginDetail.tsx
│           │   ├── SkillDetail.tsx
│           │   ├── Submit.tsx     # Submission wizard
│           │   ├── MySubmissions.tsx
│           │   └── Admin.tsx
│           ├── components/
│           │   ├── PluginCard.tsx
│           │   ├── SearchBar.tsx
│           │   ├── TagFilter.tsx
│           │   ├── MarkdownRenderer.tsx
│           │   ├── ReferenceSidebar.tsx
│           │   └── SubmissionWizard.tsx
│           ├── hooks/
│           │   ├── useAuth.ts
│           │   └── useSearch.ts
│           └── api/               # TanStack Query API client
│               └── queries.ts
├── data/                          # SQLite database (gitignored)
├── docker-compose.yml             # Production deployment
├── Dockerfile                     # Multi-stage build
├── package.json                   # npm workspace root
├── tsconfig.base.json             # Shared TS config
├── .env.example                   # Environment template
└── .gitignore
```

**Structure Decision**: npm workspaces monorepo with 3 packages. `packages/shared` provides TypeScript types shared between server and client. `packages/server` is the Express.js API with Drizzle ORM. `packages/client` is the React SPA built with Vite. In production, the built frontend is served as static files by the Express server.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| TypeScript instead of .NET | Marketplace is a Node.js ecosystem; shared types across full stack are critical for DX | .NET would require cross-language type sharing, separate build pipelines, and don't align with existing repo tooling |
| Drizzle ORM instead of EF Core | Native TypeScript ORM with excellent SQLite/FTS5 support | EF Core requires .NET runtime; no TypeScript equivalent of EF Core matches Drizzle's type safety |
| Vitest instead of xUnit | TypeScript-native test runner compatible with Vite/ESM | xUnit requires .NET runtime; Jest is heavier and slower with Vite |

## Design Artifacts

### Research

See [research.md](./research.md) for technology selection decisions and rationale.

Key decisions:
- **R-001**: TypeScript/Express.js 5 over .NET/ASP.NET Core
- **R-002**: SQLite + FTS5 with Drizzle ORM over PostgreSQL + EF Core
- **R-003**: npm workspaces monorepo with 3 packages
- **R-004**: Vitest + Playwright over xUnit + Testcontainers
- **R-005**: Microsoft Entra ID OAuth 2.0 with MSAL + session cookies
- **R-006**: React 19 + Vite 6 + Shadcn/ui + TanStack Query 5
- **R-007**: Octokit for GitHub API integration
- **R-008**: Docker single-container deployment

### Data Model

See [data-model.md](./data-model.md) for full entity definitions, DDL, relationships, and validation rules.

Key entities: Plugin, Skill, Reference, Submission, SyncState, Session

### API Contracts

| Contract File | Endpoints |
|---|---|
| [plugins-api.md](./contracts/plugins-api.md) | GET /plugins, GET /plugins/:id, GET /plugins/:id/skills/:skillId, GET /plugins/:id/skills/:skillId/references/:refId |
| [search-submissions-admin-auth-api.md](./contracts/search-submissions-admin-auth-api.md) | GET /search, POST /submissions, GET /submissions, GET /admin/stats, POST /admin/sync, Auth endpoints |

### Quickstart Guide

See [quickstart.md](./quickstart.md) for developer setup instructions, common commands, and Docker deployment guide.

## Implementation Phases

### Phase A: Foundation — Backend Core
1. Initialize npm workspace monorepo with 3 packages
2. Set up Drizzle ORM schema and migrations
3. Implement sync engine (GitHub → SQLite)
4. Build plugin catalog API (list, detail, skills, references)
5. Implement FTS5 search endpoint

### Phase B: Foundation — Frontend Core
6. Set up React + Vite + Tailwind + Shadcn/ui
7. Build catalog page with plugin cards, search, tag filtering
8. Build plugin detail page with skills list
9. Build skill detail page with markdown rendering + reference sidebar
10. Build reference document viewer

### Phase C: Authentication & Submissions
11. Implement Entra ID auth flow (MSAL + session cookies)
12. Build submission wizard (multi-step form + validation)
13. Implement submission API (validate → create branch → open PR)
14. Build "My Submissions" page with status tracking

### Phase D: Admin & Polish
15. Build admin dashboard (stats + sync trigger)
16. Implement scheduled sync (5-minute interval)
17. Add empty states, error handling, loading indicators
18. Docker setup (multi-stage build, production config)
19. E2E tests (Playwright)

## Re-evaluation: Constitution Check (Post-Design)

| Principle | Status | Notes |
|---|---|---|
| Clean Code Architecture | ✅ PASS | Services layer separates business logic from routes; DB layer isolates data access |
| DRY | ✅ PASS | Shared types package eliminates type duplication |
| KISS (max 4 projects) | ✅ PASS | 3 packages — within limit |
| Test-First | ✅ PASS | Testing infrastructure planned for all layers |
| Reusable UI | ✅ PASS | Shadcn/ui components used throughout |
| Server-Side Data Operations | ✅ PASS | All data flows through Express.js services |
| Documentation as Code | ✅ PASS | Complete contracts and data model documentation |

**Post-Design Gate Result**: PASS. All architectural principles maintained despite technology stack overrides.
# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

[Gates determined based on constitution file]

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
