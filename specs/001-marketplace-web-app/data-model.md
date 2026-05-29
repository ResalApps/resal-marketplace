# Data Model: Resal Marketplace Web Application

**Feature**: 001-marketplace-web-app  
**Date**: April 2, 2026  
**Source**: `specs/001-marketplace-web-app/spec.md` + `docs/marketplace-web-app-plan.md`

## Entity Definitions

### Plugin

The central entity representing a Claude Code plugin registered in the marketplace.

| Field | Type | Required | Description | Validation |
|---|---|---|---|---|
| id | string | yes | URL-safe slug (e.g., `add-app-deployment`) | `^[a-z][a-z0-9-]*[a-z0-9]$`, max 64 chars |
| name | string | yes | Human-readable display name | 1–128 chars |
| description | string | yes | Short description for card display | 1–500 chars |
| author | string | yes | Plugin maintainer name or org | 1–128 chars |
| repository_url | string | yes | Link to source repository | Valid HTTPS URL |
| tags | string[] | yes | Category tags for filtering | 1–10 items, each 1–50 chars |
| featured | boolean | no | Whether plugin is featured on homepage | Default: `false` |
| created_at | datetime | yes | First seen in marketplace (sync time) | ISO 8601 |
| updated_at | datetime | yes | Last modified timestamp | ISO 8601 |

**Notes**:
- `id` is derived from the directory name under `plugins/` in the source repository
- `featured` is computed: the 6 most recently updated plugins are featured (sorted by `updated_at` DESC)
- `tags` are extracted from `plugin.json` metadata in the source repo

### Skill

A capability within a plugin. Each plugin has one or more skills.

| Field | Type | Required | Description | Validation |
|---|---|---|---|---|
| id | string | yes | Composite: `{plugin_id}::{skill_name}` | Auto-generated |
| plugin_id | string (FK) | yes | Parent plugin | References `Plugin.id` |
| name | string | yes | Skill name (from SKILL.md frontmatter) | 1–128 chars |
| description | string | yes | Skill description | 1–1000 chars |
| skill_md_content | text | yes | Raw markdown content of SKILL.md | Non-empty |
| created_at | datetime | yes | Sync timestamp | ISO 8601 |
| updated_at | datetime | yes | Last modified timestamp | ISO 8601 |

**Notes**:
- Skills are discovered by scanning `plugins/{plugin-id}/skills/*/SKILL.md` in the source repo
- The skill name comes from the YAML frontmatter or the parent directory name

### Reference

A documentation reference file associated with a skill.

| Field | Type | Required | Description | Validation |
|---|---|---|---|---|
| id | string | yes | Composite: `{skill_id}::{filename}` | Auto-generated |
| skill_id | string (FK) | yes | Parent skill | References `Skill.id` |
| filename | string | yes | Filename (e.g., `deployment-checklist.md`) | Valid markdown filename |
| title | string | yes | Display title derived from filename or frontmatter | 1–200 chars |
| content | text | yes | Raw markdown content | Non-empty |
| created_at | datetime | yes | Sync timestamp | ISO 8601 |
| updated_at | datetime | yes | Last modified timestamp | ISO 8601 |

**Notes**:
- References live in `plugins/{plugin-id}/skills/{skill}/references/` in the source repo
- Title is derived by converting filename to title case and removing extension, or from YAML frontmatter

### Submission

A plugin submission tracked as a GitHub Pull Request.

| Field | Type | Required | Description | Validation |
|---|---|---|---|---|
| id | string | yes | UUID v4 | Auto-generated |
| pr_number | integer | yes | GitHub PR number | Unique |
| pr_url | string | yes | Full GitHub PR URL | Valid HTTPS URL |
| branch_name | string | yes | Git branch name (e.g., `plugin/my-plugin-2026-04-02`) | Valid git ref |
| status | enum | yes | Current PR status | One of: `open`, `merged`, `closed` |
| plugin_id | string | yes | Submitted plugin slug | `^[a-z][a-z0-9-]*[a-z0-9]$` |
| plugin_name | string | yes | Display name at time of submission | 1–128 chars |
| submitted_by | string | yes | Entra ID user principal name or object ID | Non-empty |
| submitted_at | datetime | yes | Submission timestamp | ISO 8601 |
| updated_at | datetime | yes | Last status change timestamp | ISO 8601 |

**State Transitions**:
```
[created] → open → merged    (PR approved and merged)
                  → closed    (PR declined or withdrawn)
```

**Notes**:
- Status is polled from GitHub API during sync cycles
- `merged` status triggers marketplace.json update and re-indexing

### SyncState

Singleton tracking the last successful GitHub sync.

| Field | Type | Required | Description | Validation |
|---|---|---|---|---|
| id | integer | yes | Always `1` (singleton) | Fixed |
| last_sync_at | datetime | yes | Timestamp of last successful sync | ISO 8601 |
| last_commit_sha | string | yes | SHA of last processed commit | 40-char hex |
| status | enum | yes | Current sync status | One of: `idle`, `syncing`, `error` |
| error_message | text | no | Last error message if status is `error` | Nullable |
| plugin_count | integer | yes | Number of plugins at last sync | ≥ 0 |
| skill_count | integer | yes | Number of skills at last sync | ≥ 0 |

**Notes**:
- Only one row ever exists (id = 1)
- Updated after each sync cycle (startup + every 5 minutes)

### Session

HTTP session for authenticated users.

| Field | Type | Required | Description | Validation |
|---|---|---|---|---|
| id | string | yes | Session ID (UUID v4) | Auto-generated |
| user_id | string | yes | Entra ID user principal name | Non-empty |
| display_name | string | yes | User display name from Entra ID | 1–256 chars |
| access_token | text | yes | Encrypted Entra ID access token | Non-empty |
| created_at | datetime | yes | Session creation time | ISO 8601 |
| expires_at | datetime | yes | Session expiration time | ISO 8601 |

**Notes**:
- Sessions expire after 24 hours
- Access tokens are encrypted at rest using AES-256-GCM with a server-side key

## Relationships

```
Plugin 1──* Skill        (a plugin has many skills)
Skill  1──* Reference    (a skill has many references)
Plugin 1──* Submission   (a plugin may have many submissions over time)
SyncState is singleton   (exactly one row)
Session  is per-user     (multiple sessions per user possible)
```

## SQLite DDL

```sql
-- Main entities
CREATE TABLE plugins (
  id            TEXT PRIMARY KEY,           -- slug from directory name
  name          TEXT NOT NULL,
  description   TEXT NOT NULL,
  author        TEXT NOT NULL,
  repository_url TEXT NOT NULL,
  tags          TEXT NOT NULL DEFAULT '[]', -- JSON array of strings
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE skills (
  id              TEXT PRIMARY KEY,           -- {plugin_id}::{skill_name}
  plugin_id       TEXT NOT NULL REFERENCES plugins(id) ON DELETE CASCADE,
  name            TEXT NOT NULL,
  description     TEXT NOT NULL,
  skill_md_content TEXT NOT NULL,
  created_at      TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE references (
  id          TEXT PRIMARY KEY,           -- {skill_id}::{filename}
  skill_id    TEXT NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  filename    TEXT NOT NULL,
  title       TEXT NOT NULL,
  content     TEXT NOT NULL,
  created_at  TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Submissions tracking
CREATE TABLE submissions (
  id            TEXT PRIMARY KEY,           -- UUID v4
  pr_number     INTEGER NOT NULL UNIQUE,
  pr_url        TEXT NOT NULL,
  branch_name   TEXT NOT NULL,
  status        TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'merged', 'closed')),
  plugin_id     TEXT NOT NULL,
  plugin_name   TEXT NOT NULL,
  submitted_by  TEXT NOT NULL,
  submitted_at  TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Sync state (singleton)
CREATE TABLE sync_state (
  id              INTEGER PRIMARY KEY CHECK (id = 1),
  last_sync_at    TEXT NOT NULL,
  last_commit_sha TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'idle' CHECK (status IN ('idle', 'syncing', 'error')),
  error_message   TEXT,
  plugin_count    INTEGER NOT NULL DEFAULT 0,
  skill_count     INTEGER NOT NULL DEFAULT 0
);

-- User sessions
CREATE TABLE sessions (
  id            TEXT PRIMARY KEY,           -- UUID v4
  user_id       TEXT NOT NULL,
  display_name  TEXT NOT NULL,
  access_token  TEXT NOT NULL,              -- encrypted
  created_at    TEXT NOT NULL DEFAULT (datetime('now')),
  expires_at    TEXT NOT NULL
);

-- FTS5 virtual table for full-text search
CREATE VIRTUAL TABLE plugins_fts USING fts5(
  plugin_id,
  name,
  description,
  tags,
  skill_content,
  reference_content,
  content='',
  tokenize='porter unicode61'
);

-- Indexes
CREATE INDEX idx_skills_plugin_id ON skills(plugin_id);
CREATE INDEX idx_references_skill_id ON references(skill_id);
CREATE INDEX idx_submissions_status ON submissions(status);
CREATE INDEX idx_submissions_submitted_by ON submissions(submitted_by);
CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX idx_plugins_updated_at ON plugins(updated_at);
```

## Validation Rules

| Rule | Entity | Field(s) | Description |
|---|---|---|---|
| V-001 | Plugin | id | Must match `^[a-z][a-z0-9-]*[a-z0-9]$`, 2–64 chars |
| V-002 | Plugin | tags | JSON array with 1–10 items, each 1–50 chars |
| V-003 | Submission | plugin_id | Must not match an existing plugin id (no duplicates) |
| V-004 | Submission | plugin_name | Must be 1–128 chars, non-empty |
| V-005 | Session | expires_at | Must be > `created_at` |
| V-006 | Reference | filename | Must end in `.md` |
| V-007 | Plugin | repository_url | Must be valid HTTPS URL |

## FTS5 Index Strategy

The `plugins_fts` virtual table aggregates content from multiple entities for unified search:

1. **On sync**: For each plugin, concatenate:
   - `name` and `description` from the plugin
   - `tags` joined as space-separated tokens
   - All skill descriptions (`skill_content`)
   - All reference content (`reference_content`)
2. **Search query**: `SELECT plugin_id FROM plugins_fts WHERE plugins_fts MATCH ? ORDER BY rank`
3. **Result joining**: Join FTS results back to `plugins` table for full metadata
4. **Tag filtering**: Additional `WHERE tags LIKE '%"tagname"%'` clause applied after FTS
