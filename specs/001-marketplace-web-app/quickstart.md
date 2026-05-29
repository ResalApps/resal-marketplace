# Quickstart: Resal Marketplace Web Application

**Feature**: 001-marketplace-web-app  
**Date**: April 2, 2026

## Prerequisites

- **Node.js** 22+ (LTS)
- **npm** 10+ (bundled with Node.js)
- **Docker** + Docker Compose (for production deployment)
- **Git** (for version control)
- **Microsoft Entra ID** tenant (for authentication — optional for local dev without auth)
- **GitHub Personal Access Token** or GitHub App credentials (for marketplace sync)

## Local Development Setup

### 1. Clone and Install

```bash
git clone https://github.com/Resal/resal-marketplace.git
cd resal-marketplace
git checkout 001-marketplace-web-app

# Install all workspace dependencies
npm install
```

### 2. Environment Configuration

Copy the environment template and fill in values:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Server
PORT=4000
NODE_ENV=development

# GitHub Integration
GITHUB_TOKEN=ghp_your_token_here
GITHUB_REPO_OWNER=Resal
GITHUB_REPO_NAME=resal-marketplace

# Database
DATABASE_PATH=./data/marketplace.db

# Auth (Microsoft Entra ID)
ENTRA_CLIENT_ID=your-client-id
ENTRA_CLIENT_SECRET=your-client-secret
ENTRA_TENANT_ID=your-tenant-id
ENTRA_REDIRECT_URI=http://localhost:4000/api/auth/callback

# Session
SESSION_SECRET=a-random-32-byte-secret
SESSION_MAX_AGE_HOURS=24

# Sync
SYNC_INTERVAL_MINUTES=5
```

### 3. Build Shared Package

```bash
# Build shared types first (required by both server and client)
npm run build --workspace=packages/shared
```

### 4. Start Development Servers

```bash
# Start all services (server + client with hot reload)
npm run dev
```

This starts:
- **API server** at `http://localhost:4000/api` (Express with hot reload via `tsx watch`)
- **Frontend dev server** at `http://localhost:5173` (Vite with HMR, proxying `/api` to backend)

On first startup, the sync engine will:
1. Connect to GitHub API using `GITHUB_TOKEN`
2. Read `marketplace.json` and all plugin files
3. Parse plugins, skills, and references into SQLite
4. Build the FTS5 search index

### 5. Verify Setup

```bash
# Check API is running
curl http://localhost:4000/api/plugins

# Check search works
curl "http://localhost:4000/api/search?q=deployment"

# Check sync status
curl http://localhost:4000/api/admin/sync/status
```

Open `http://localhost:5173` in your browser to see the marketplace UI.

## Project Structure

```
resal-marketplace/
├── packages/
│   ├── shared/           # Shared TypeScript types
│   │   └── src/
│   │       └── types.ts  # API request/response types
│   ├── server/           # Express.js backend
│   │   └── src/
│   │       ├── index.ts          # Entry point
│   │       ├── routes/           # API route handlers
│   │       ├── services/         # Business logic
│   │       │   ├── sync.ts       # GitHub sync engine
│   │       │   ├── submissions.ts # Submission workflow
│   │       │   └── auth.ts       # Entra ID auth
│   │       ├── db/               # Drizzle ORM schema + queries
│   │       │   ├── schema.ts     # Table definitions
│   │       │   └── migrations/   # SQL migration files
│   │       └── middleware/        # Auth, error handling
│   └── client/           # React frontend
│       └── src/
│           ├── App.tsx           # Root component
│           ├── pages/            # Route pages
│           │   ├── Catalog.tsx   # Browse plugins
│           │   ├── PluginDetail.tsx
│           │   ├── SkillDetail.tsx
│           │   ├── Submit.tsx    # Submission wizard
│           │   ├── MySubmissions.tsx
│           │   └── Admin.tsx
│           ├── components/       # Reusable UI components
│           ├── hooks/            # Custom React hooks
│           └── api/              # API client functions
├── data/                  # SQLite database (gitignored)
├── docker-compose.yml     # Production deployment
├── Dockerfile             # Multi-stage build
├── package.json           # npm workspace root
└── .env.example           # Environment template
```

## Common Commands

| Command | Description |
|---|---|
| `npm run dev` | Start all services with hot reload |
| `npm run build` | Build all packages for production |
| `npm test` | Run all tests (Vitest + Supertest) |
| `npm run test:e2e` | Run Playwright E2E tests |
| `npm run lint` | Lint all packages with ESLint |
| `npm run format` | Format code with Prettier |
| `npm run db:migrate` | Run Drizzle migrations |
| `npm run db:studio` | Open Drizzle Studio (DB GUI) |

## Docker Deployment

```bash
# Build and start production container
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

The Docker setup:
- Uses multi-stage build (build frontend → serve from Express static)
- Persists SQLite database via Docker volume `./data:/app/data`
- Single container on port 4000

## Testing

### Unit Tests
```bash
# Run all unit tests
npm test

# Run with coverage
npm test -- --coverage

# Watch mode
npm test -- --watch
```

### Integration Tests
```bash
# API integration tests (uses SQLite :memory:)
npm test -- packages/server
```

### E2E Tests
```bash
# Requires running dev server
npm run dev &
npm run test:e2e
```

## Troubleshooting

| Issue | Solution |
|---|---|
| "Database is locked" | Only one server process can access SQLite. Stop other instances. |
| "GitHub API rate limit" | Check `GITHUB_TOKEN` is set. Authenticated requests get 5,000 req/hr. |
| "Empty catalog after startup" | Check sync engine logs. Verify `GITHUB_TOKEN` has repo read access. |
| "Auth redirect fails" | Verify Entra ID redirect URI matches `ENTRA_REDIRECT_URI` exactly. |
| "FTS5 not found" | SQLite must be compiled with FTS5. Use `better-sqlite3` which includes it. |
