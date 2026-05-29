# API Contracts: Search, Submissions, Admin, Auth

**Feature**: 001-marketplace-web-app  
**Base URL**: `http://localhost:4000/api`

---

## GET /api/search

Full-text search across all plugins, skills, and references using SQLite FTS5.

**Authentication**: None required

### Request

**Query Parameters**:

| Parameter | Type | Default | Description |
|---|---|---|---|
| q | string | (required) | Search query |
| page | integer | 1 | Page number (1-based) |
| pageSize | integer | 20 | Items per page (max 100) |
| tag | string | null | Filter by tag (exact match) |
| sort | string | relevance | Sort: `relevance`, `updated_at`, `name` |
| order | string | desc | Sort order: `asc`, `desc` |

**Example**:
```
GET /api/search?q=deployment&tag=kubernetes&sort=relevance&page=1&pageSize=20
```

### Response

**200 OK**:
```json
{
  "data": [
    {
      "id": "add-app-deployment",
      "name": "Add App Deployment",
      "description": "Deploy applications to Kubernetes with Helm",
      "author": "Resal Team",
      "tags": ["deployment", "kubernetes", "helm"],
      "skillCount": 1,
      "createdAt": "2025-01-15T10:30:00Z",
      "updatedAt": "2026-03-20T14:22:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

**Empty query** (no `q` parameter):
```json
{
  "error": "Search query parameter 'q' is required"
}
```

---

## POST /api/submissions

Submit a new plugin to the marketplace. Creates a GitHub branch and PR with all plugin files.

**Authentication**: Required (Entra ID session cookie)

### Request

**Headers**:
```
Cookie: session_id=<uuid>
Content-Type: application/json
```

**Body**:
```json
{
  "pluginId": "my-new-plugin",
  "pluginName": "My New Plugin",
  "description": "A brief description of what this plugin does",
  "author": "Jane Developer",
  "repositoryUrl": "https://github.com/janedev/my-new-plugin",
  "tags": ["automation", "testing"],
  "skills": [
    {
      "name": "my-skill",
      "description": "Skill description",
      "content": "# My Skill\n\nFull SKILL.md markdown content here...",
      "references": [
        {
          "filename": "getting-started.md",
          "title": "Getting Started",
          "content": "# Getting Started\n\nInstructions..."
        }
      ]
    }
  ]
}
```

**Validation Rules**:
- `pluginId`: Must match `^[a-z][a-z0-9-]*[a-z0-9]$`, 2–64 chars
- `pluginId`: Must NOT already exist in marketplace
- `pluginName`: 1–128 chars, non-empty
- `description`: 1–500 chars
- `tags`: 1–10 items, each 1–50 chars
- `skills`: At least 1 skill required
- Each skill must have `name`, `description`, and `content`
- Reference filenames must end in `.md`

### Response

**202 Accepted**:
```json
{
  "id": "sub_abc123-def456-...",
  "prNumber": 42,
  "prUrl": "https://github.com/Resal/resal-marketplace/pull/42",
  "branchName": "plugin/my-new-plugin-2026-04-02",
  "status": "open",
  "pluginId": "my-new-plugin",
  "pluginName": "My New Plugin",
  "submittedAt": "2026-04-02T10:30:00Z"
}
```

**400 Bad Request** (validation failure):
```json
{
  "error": "Plugin ID 'my-new-plugin' already exists in the marketplace"
}
```

**401 Unauthorized** (no session):
```json
{
  "error": "Authentication required. Please log in."
}
```

---

## GET /api/submissions

List the authenticated user's submissions.

**Authentication**: Required (Entra ID session cookie)

### Request

**Query Parameters**:

| Parameter | Type | Default | Description |
|---|---|---|---|
| page | integer | 1 | Page number (1-based) |
| pageSize | integer | 20 | Items per page (max 100) |
| status | string | null | Filter by status: `open`, `merged`, `closed` |

**Example**:
```
GET /api/submissions?status=open&page=1
```

### Response

**200 OK**:
```json
{
  "data": [
    {
      "id": "sub_abc123-def456-...",
      "prNumber": 42,
      "prUrl": "https://github.com/Resal/resal-marketplace/pull/42",
      "branchName": "plugin/my-new-plugin-2026-04-02",
      "status": "open",
      "pluginId": "my-new-plugin",
      "pluginName": "My New Plugin",
      "submittedBy": "jane.developer@contoso.com",
      "submittedAt": "2026-04-02T10:30:00Z",
      "updatedAt": "2026-04-02T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

**401 Unauthorized**:
```json
{
  "error": "Authentication required. Please log in."
}
```

---

## GET /api/submissions/:id

Get details of a specific submission belonging to the authenticated user.

**Authentication**: Required (Entra ID session cookie)

### Request

**Path Parameters**:

| Name | Type | Description |
|---|---|---|
| id | string | Submission UUID |

### Response

**200 OK**: Same shape as individual submission item from list endpoint.

**403 Forbidden**:
```json
{
  "error": "You do not have access to this submission"
}
```

**404 Not Found**:
```json
{
  "error": "Submission not found"
}
```

---

## GET /api/admin/stats

Get marketplace statistics for the admin dashboard.

**Authentication**: Required (Entra ID session cookie + admin role)

### Response

**200 OK**:
```json
{
  "totalPlugins": 42,
  "totalSkills": 67,
  "totalReferences": 213,
  "totalTags": 15,
  "totalSubmissions": 12,
  "openSubmissions": 3,
  "recentlyAdded": [
    {
      "id": "my-new-plugin",
      "name": "My New Plugin",
      "createdAt": "2026-04-01T10:00:00Z"
    }
  ],
  "topTags": [
    { "tag": "deployment", "count": 8 },
    { "tag": "kubernetes", "count": 6 },
    { "tag": "testing", "count": 5 }
  ]
}
```

**403 Forbidden**:
```json
{
  "error": "Admin access required"
}
```

---

## POST /api/admin/sync

Trigger a manual re-sync from GitHub.

**Authentication**: Required (Entra ID session cookie + admin role)

### Response

**202 Accepted**:
```json
{
  "message": "Sync initiated",
  "status": "syncing"
}
```

**409 Conflict** (sync already in progress):
```json
{
  "error": "Sync already in progress. Please wait for it to complete."
}
```

---

## GET /api/admin/sync/status

Get the current sync engine status.

**Authentication**: Required (Entra ID session cookie + admin role)

### Response

**200 OK**:
```json
{
  "status": "idle",
  "lastSyncAt": "2026-04-02T10:25:00Z",
  "lastCommitSha": "abc123def456...",
  "pluginCount": 42,
  "skillCount": 67,
  "errorMessage": null
}
```

**When sync is in progress**:
```json
{
  "status": "syncing",
  "lastSyncAt": "2026-04-02T10:20:00Z",
  "lastCommitSha": "abc123def456...",
  "pluginCount": 42,
  "skillCount": 67,
  "errorMessage": null
}
```

**When sync has errored**:
```json
{
  "status": "error",
  "lastSyncAt": "2026-04-02T10:20:00Z",
  "lastCommitSha": "abc123def456...",
  "pluginCount": 42,
  "skillCount": 67,
  "errorMessage": "GitHub API rate limit exceeded. Retry after 2026-04-02T11:00:00Z."
}
```

---

## Auth Endpoints

### GET /api/auth/login

Redirects to Microsoft Entra ID login page. After successful authentication, redirects to `/api/auth/callback`.

**No authentication required.**

### GET /api/auth/callback

OAuth 2.0 callback handler. Exchanges authorization code for tokens, creates server-side session, redirects to frontend.

**No authentication required.**

**On success**: Redirects to `http://localhost:5173/?auth=success`
**On failure**: Redirects to `http://localhost:5173/?auth=error&message=...`

### POST /api/auth/logout

Clears the server-side session and Entra ID session.

**Request**:
```
Cookie: session_id=<uuid>
```

**Response** `200 OK`:
```json
{
  "message": "Logged out successfully"
}
```

---

## Error Response Format

All errors follow a consistent format:

```json
{
  "error": "Human-readable error message"
}
```

| Status | When |
|---|---|
| 400 | Validation failure, malformed request |
| 401 | Authentication required but missing |
| 403 | Authenticated but insufficient permissions |
| 404 | Resource not found |
| 409 | Conflict (e.g., sync already in progress, duplicate plugin) |
| 500 | Unexpected server error |
