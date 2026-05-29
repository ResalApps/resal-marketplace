# Plugin Catalog API

## GET /api/plugins

List all plugins in the catalog with pagination and sorting.

**Authentication**: None required

### Request

**Query Parameters**:

| Name | Type | Default | Description |
|---|---|---|---|
| page | integer | 1 | Page number (1-based) |
| pageSize | integer | 20 | Items per page (max 100) |
| sort | string | updated_at | Sort field: `updated_at`, `name`, `created_at` |
| order | string | desc | Sort order: `asc`, `desc` |
| tag | string | — | Filter by tag (exact match) |

**Example**:
```
GET /api/plugins?page=1&pageSize=20&sort=updated_at&order=desc&tag=deployment
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

**400 Bad Request**:
```json
{
  "error": "Invalid parameter: pageSize must be between 1 and 100"
}
```

---

## GET /api/plugins/:id

Get full plugin detail including skills list and metadata.

**Authentication**: None required

### Request

**Path Parameters**:

| Name | Type | Description |
|---|---|---|
| id | string | Plugin slug (e.g., `add-app-deployment`) |

**Example**:
```
GET /api/plugins/add-app-deployment
```

### Response

**200 OK**:
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
      "description": "Plan, scaffold, extend, and deploy applications to Kubernetes",
      "referenceCount": 4
    }
  ]
}
```

**404 Not Found**:
```json
{
  "error": "Plugin not found: non-existent-plugin"
}
```

---

## GET /api/plugins/:id/skills/:skillId

Get skill detail with rendered SKILL.md content and reference list.

**Authentication**: None required

### Request

**Path Parameters**:

| Name | Type | Description |
|---|---|---|
| id | string | Plugin slug |
| skillId | string | Skill ID (URL-encoded) |

**Example**:
```
GET /api/plugins/add-app-deployment/skills/add-app-deployment%3A%3Aadd-app-deployment
```

### Response

**200 OK**:
```json
{
  "id": "add-app-deployment::add-app-deployment",
  "pluginId": "add-app-deployment",
  "name": "Add App Deployment",
  "description": "Plan, scaffold, extend, and deploy applications to Kubernetes",
  "content": "# Add App Deployment\n\nFull SKILL.md markdown content here...",
  "references": [
    {
      "id": "add-app-deployment::add-app-deployment::deployment-checklist.md",
      "filename": "deployment-checklist.md",
      "title": "Deployment Checklist"
    },
    {
      "id": "add-app-deployment::add-app-deployment::helm-templates.md",
      "filename": "helm-templates.md",
      "title": "Helm Templates"
    },
    {
      "id": "add-app-deployment::add-app-deployment::infrastructure-conventions.md",
      "filename": "infrastructure-conventions.md",
      "title": "Infrastructure Conventions"
    },
    {
      "id": "add-app-deployment::add-app-deployment::workflow-templates.md",
      "filename": "workflow-templates.md",
      "title": "Workflow Templates"
    }
  ]
}
```

**404 Not Found**:
```json
{
  "error": "Skill not found: invalid-skill-id"
}
```

---

## GET /api/plugins/:id/skills/:skillId/references/:refId

Get a single reference document with full markdown content.

**Authentication**: None required

### Request

**Path Parameters**:

| Name | Type | Description |
|---|---|---|
| id | string | Plugin slug |
| skillId | string | Skill ID (URL-encoded) |
| refId | string | Reference ID (URL-encoded) |

**Example**:
```
GET /api/plugins/add-app-deployment/skills/add-app-deployment%3A%3Aadd-app-deployment/references/add-app-deployment%3A%3Aadd-app-deployment%3A%3Adeployment-checklist.md
```

### Response

**200 OK**:
```json
{
  "id": "add-app-deployment::add-app-deployment::deployment-checklist.md",
  "skillId": "add-app-deployment::add-app-deployment",
  "filename": "deployment-checklist.md",
  "title": "Deployment Checklist",
  "content": "# Deployment Checklist\n\nFull reference markdown content here..."
}
```

**404 Not Found**:
```json
{
  "error": "Reference not found"
}
```
