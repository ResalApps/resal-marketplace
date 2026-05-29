# API Contracts: Resal Marketplace Web Application

**Feature**: 001-marketplace-web-app  
**Date**: April 2, 2026  
**Base URL**: `http://localhost:4000/api`

## Overview

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/plugins` | No | List all plugins (catalog) |
| GET | `/plugins/:id` | No | Get plugin detail |
| GET | `/plugins/:id/skills/:skillId` | No | Get skill detail with markdown |
| GET | `/plugins/:id/skills/:skillId/references/:refId` | No | Get reference document |
| GET | `/search` | No | Full-text search across plugins |
| POST | `/submissions` | Yes | Submit a new plugin |
| GET | `/submissions` | Yes | List user's submissions |
| GET | `/submissions/:id` | Yes | Get submission detail |
| GET | `/admin/stats` | Yes (admin) | Marketplace statistics |
| POST | `/admin/sync` | Yes (admin) | Trigger manual sync |
| GET | `/admin/sync/status` | Yes (admin) | Get sync status |
| GET | `/auth/login` | No | Redirect to Entra ID login |
| GET | `/auth/callback` | No | OAuth callback handler |
| POST | `/auth/logout` | No | Clear session |

## Shared Types

```typescript
// packages/shared/src/types.ts

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
  };
}

export interface Plugin {
  id: string;
  name: string;
  description: string;
  author: string;
  repositoryUrl: string;
  tags: string[];
  skillCount: number;
  createdAt: string;   // ISO 8601
  updatedAt: string;   // ISO 8601
}

export interface PluginDetail extends Plugin {
  skills: SkillSummary[];
}

export interface SkillSummary {
  id: string;
  name: string;
  description: string;
  referenceCount: number;
}

export interface SkillDetail {
  id: string;
  pluginId: string;
  name: string;
  description: string;
  content: string;     // Raw SKILL.md markdown
  references: ReferenceSummary[];
}

export interface ReferenceSummary {
  id: string;
  filename: string;
  title: string;
}

export interface ReferenceDetail {
  id: string;
  skillId: string;
  filename: string;
  title: string;
  content: string;     // Raw markdown content
}

export interface Submission {
  id: string;
  prNumber: number;
  prUrl: string;
  branchName: string;
  status: 'open' | 'merged' | 'closed';
  pluginId: string;
  pluginName: string;
  submittedBy: string;
  submittedAt: string;
  updatedAt: string;
}

export interface SubmissionPayload {
  pluginId: string;
  pluginName: string;
  description: string;
  author: string;
  repositoryUrl: string;
  tags: string[];
  skills: SkillPayload[];
}

export interface SkillPayload {
  name: string;
  description: string;
  content: string;         // SKILL.md content
  references: ReferencePayload[];
}

export interface ReferencePayload {
  filename: string;
  title: string;
  content: string;
}

export interface SyncStatus {
  lastSyncAt: string;
  lastCommitSha: string;
  status: 'idle' | 'syncing' | 'error';
  errorMessage: string | null;
  pluginCount: number;
  skillCount: number;
}

export interface MarketplaceStats {
  totalPlugins: number;
  totalSkills: number;
  totalSubmissions: number;
  pendingSubmissions: number;
  recentPlugins: Plugin[];    // Last 5 added
  topTags: { tag: string; count: number }[];
}

export interface SearchFilters {
  q?: string;         // Search query
  tag?: string;       // Tag filter
  page?: number;      // 1-based, default 1
  pageSize?: number;  // Default 20, max 100
  sort?: 'updated_at' | 'name' | 'created_at';  // Default 'updated_at'
  order?: 'asc' | 'desc';  // Default 'desc'
}

export interface ErrorResponse {
  error: string;
  message: string;
  statusCode: number;
}
```

## Endpoint Contracts

---

### GET /api/plugins

List plugins in the catalog with pagination and sorting.

**Request**:
```
GET /api/plugins?page=1&pageSize=20&sort=updated_at&order=desc
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| page | integer | 1 | Page number (1-based) |
| pageSize | integer | 20 | Items per page (max 100) |
| sort | string | updated_at | Sort field: `updated_at`, `name`, `created_at` |
| order | string | desc | Sort order: `asc`, `desc` |

**Response** `200 OK`:
```json
{
  "data": [
    {
      "id": "add-app-deployment",
      "name": "Add App Deployment",
      "description": "Deploy applications to Kubernetes with Helm",
      "author": "Resal Team",
      "repositoryUrl": "https://github.com/resal/resal-marketplace",
      "tags": ["deployment", "kubernetes", "helm"],
      "skillCount": 1,
      "createdAt": "2025-01-15T10:30:00Z",
      "updatedAt": "2026-03-20T14:22:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 42,
    "totalPages": 3
  }
}
```

---

### GET /api/plugins/:id

Get full plugin detail including skills list.

**Request**:
```
GET /api/plugins/add-app-deployment
```

**Response** `200 OK`:
```json
{
  "id": "add-app-deployment",
  "name": "Add App Deployment",
  "description": "Deploy applications to Kubernetes with Helm",
  "author": "Resal Team",
  "repositoryUrl": "https://github.com/resal/resal-marketplace",
  "tags": ["deployment", "kubernetes", "helm"],
  "skillCount": 1,
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2026-03-20T14:22:00Z",
  "skills": [
    {
      "id": "add-app-deployment::add-app-deployment",
      "name": "Add App Deployment",
      "description": "Guide for deploying applications to Kubernetes",
      "referenceCount": 4
    }
  ]
}
```

**Error** `404 Not Found`:
```json
{
  "error": "NOT_FOUND",
  "message": "Plugin 'nonexistent' not found",
  "statusCode": 404
}
```

---

### GET /api/plugins/:id/skills/:skillId

Get skill detail including SKILL.md content and reference list.

**Request**:
```
GET /api/plugins/add-app-deployment/skills/add-app-deployment
```

**Response** `200 OK`:
```json
{
  "id": "add-app-deployment::add-app-deployment",
  "pluginId": "add-app-deployment",
  "name": "Add App Deployment",
  "description": "Guide for deploying applications to Kubernetes",
  "content": "# Add App Deployment\n\n## Overview\n...",
  "references": [
    {
      "id": "add-app-deployment::add-app-deployment::deployment-checklist.md",
      "filename": "deployment-checklist.md",
      "title": "Deployment Checklist"
    }
  ]
}
```

---

### GET /api/plugins/:id/skills/:skillId/references/:refId

Get a single reference document with full markdown content.

**Request**:
```
GET /api/plugins/add-app-deployment/skills/add-app-deployment/references/deployment-checklist.md
```

**Response** `200 OK`:
```json
{
  "id": "add-app-deployment::add-app-deployment::deployment-checklist.md",
  "skillId": "add-app-deployment::add-app-deployment",
  "filename": "deployment-checklist.md",
  "title": "Deployment Checklist",
  "content": "# Deployment Checklist\n\n## Pre-deployment\n- [ ] Verify Helm chart..."
}
```

---

### GET /api/search

Full-text search across all plugin content using FTS5.

**Request**:
```
GET /api/search?q=deployment&tag=kubernetes&page=1&pageSize=20&sort=updated_at&order=desc
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| q | string | — | Search query (FTS5 syntax) |
| tag | string | — | Filter by tag |
| page | integer | 1 | Page number |
| pageSize | integer | 20 | Items per page (max 100) |
| sort | string | updated_at | Sort field |
| order | string | desc | Sort order |

**Response** `200 OK`:
```json
{
  "data": [
    {
      "id": "add-app-deployment",
      "name": "Add App Deployment",
      "description": "Deploy applications to Kubernetes with Helm",
      "author": "Resal Team",
      "repositoryUrl": "https://github.com/resal/resal-marketplace",
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

**Note**: When `q` is empty/missing and `tag` is provided, returns all plugins matching the tag. When both are empty, returns all plugins (equivalent to `GET /api/plugins`).

---

### POST /api/submissions

Submit a new plugin to the marketplace. Creates a GitHub branch and PR.

**Auth**: Required (Entra ID session)

**Request**:
```json
{
  "pluginId": "my-new-plugin",
  "pluginName": "My New Plugin",
  "description": "A plugin that does something useful",
  "author": "Jane Developer",
  "repositoryUrl": "https://github.com/jane/my-plugin",
  "tags": ["automation", "ci-cd"],
  "skills": [
    {
      "name": "Automate Deploys",
      "description": "Automate deployment pipelines",
      "content": "# Automate Deploys\n\n## Overview\n...",
      "references": [
        {
          "filename": "pipeline-setup.md",
          "title": "Pipeline Setup",
          "content": "# Pipeline Setup\n\n## Prerequisites\n..."
        }
      ]
    }
  ]
}
```

**Response** `202 Accepted`:
```json
{
  "id": "sub_abc123-def456",
  "prNumber": 42,
  "prUrl": "https://github.com/resal/resal-marketplace/pull/42",
  "branchName": "plugin/my-new-plugin-2026-04-02",
  "status": "open",
  "pluginId": "my-new-plugin",
  "pluginName": "My New Plugin",
  "submittedBy": "jane@contoso.com",
  "submittedAt": "2026-04-02T10:30:00Z",
  "updatedAt": "2026-04-02T10:30:00Z"
}
```

**Error** `409 Conflict` (duplicate plugin ID):
```json
{
  "error": "CONFLICT",
  "message": "Plugin 'add-app-deployment' already exists in the marketplace",
  "statusCode": 409
}
```

**Error** `400 Bad Request` (validation failure):
```json
{
  "error": "VALIDATION_ERROR",
  "message": "pluginId must match pattern ^[a-z][a-z0-9-]*[a-z0-9]$",
  "statusCode": 400
}
```

**Error** `401 Unauthorized`:
```json
{
  "error": "UNAUTHORIZED",
  "message": "Authentication required to submit plugins",
  "statusCode": 401
}
```

---

### GET /api/submissions

List the current user's submissions.

**Auth**: Required

**Request**:
```
GET /api/submissions?page=1&pageSize=20&status=open
```

| Parameter | Type | Default | Description |
|---|---|---|---|
| page | integer | 1 | Page number |
| pageSize | integer | 20 | Items per page |
| status | string | — | Filter by status: `open`, `merged`, `closed` |

**Response** `200 OK`:
```json
{
  "data": [
    {
      "id": "sub_abc123-def456",
      "prNumber": 42,
      "prUrl": "https://github.com/resal/resal-marketplace/pull/42",
      "branchName": "plugin/my-new-plugin-2026-04-02",
      "status": "open",
      "pluginId": "my-new-plugin",
      "pluginName": "My New Plugin",
      "submittedBy": "jane@contoso.com",
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

---

### GET /api/submissions/:id

Get a single submission detail.

**Auth**: Required (only own submissions visible)

**Response** `200 OK`: Same shape as single Submission object.

---

### GET /api/admin/stats

Get marketplace statistics for admin dashboard.

**Auth**: Required (admin role)

**Response** `200 OK`:
```json
{
  "totalPlugins": 42,
  "totalSkills": 67,
  "totalSubmissions": 15,
  "pendingSubmissions": 3,
  "recentPlugins": [ /* last 5 Plugin objects */ ],
  "topTags": [
    { "tag": "deployment", "count": 12 },
    { "tag": "kubernetes", "count": 8 }
  ]
}
```

---

### POST /api/admin/sync

Trigger a manual sync from GitHub.

**Auth**: Required (admin role)

**Response** `202 Accepted`:
```json
{
  "status": "syncing",
  "message": "Sync initiated"
}
```

---

### GET /api/admin/sync/status

Get current sync status.

**Auth**: Required (admin role)

**Response** `200 OK`:
```json
{
  "lastSyncAt": "2026-04-02T10:25:00Z",
  "lastCommitSha": "abc123def456...",
  "status": "idle",
  "errorMessage": null,
  "pluginCount": 42,
  "skillCount": 67
}
```

---

### Auth Endpoints

#### GET /api/auth/login

Redirects to Microsoft Entra ID authorization endpoint.

**Response**: `302 Redirect` to `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize?...`

#### GET /api/auth/callback

Handles OAuth callback, creates session.

**Response**: `302 Redirect` to `/` with `Set-Cookie: session_id=...; HttpOnly; Secure; SameSite=Lax`

#### POST /api/auth/logout

Clears session cookie and deletes session from DB.

**Response**: `200 OK`
```json
{
  "message": "Logged out successfully"
}
```
