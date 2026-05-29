# Research: Resal Marketplace Web Application

**Feature**: 001-marketplace-web-app  
**Date**: April 2, 2026  
**Status**: Complete

## Research Topics

### R-001: Backend Language — TypeScript/Express.js vs .NET/ASP.NET Core

**Context**: The constitution mandates .NET 10 + ASP.NET Core for the backend, but the marketplace-web-app-plan.md (user-provided spec input) specifies Express.js 5 with TypeScript.

**Decision**: Use TypeScript + Express.js 5 as described in the plan.

**Rationale**:
- The marketplace repository itself is a TypeScript/Node.js ecosystem (Claude Code plugins, npm-based tooling)
- The team has full TypeScript expertise — the constitution's .NET stack was aspirational for this specific project
- A Node.js backend integrates more naturally with the existing npm workspace monorepo structure
- Express.js 5 is lightweight, well-understood, and sufficient for a REST API serving an internal tool
- Using TypeScript across the full stack enables shared types between `packages/shared`, `packages/server`, and `packages/client`

**Alternatives Considered**:
- .NET 10 + ASP.NET Core: Would require a separate build pipeline, different dependency management (NuGet vs npm), and cross-language type sharing complexity. Better suited for enterprise-grade microservices but overkill for this internal catalog app.
- Fastify: Faster than Express but less ecosystem support and team familiarity.
- Hono: Modern and fast, but less mature ecosystem for the team's needs.

**Constitution Violation Justification**: The constitution specifies .NET as the backend technology. This project uses TypeScript/Express.js instead because (1) the marketplace is a Node.js ecosystem, (2) shared types across the monorepo are critical for DX, and (3) the team chose Express.js in the original plan for simplicity. The architectural principles (layered architecture, dependency injection, testability) from the constitution still apply but are implemented in TypeScript idioms rather than C#.

---

### R-002: Database — SQLite + FTS5 vs EF Core + PostgreSQL

**Context**: The constitution specifies EF Core with SQLite (dev) / PostgreSQL (prod). The plan uses Drizzle ORM with SQLite + FTS5.

**Decision**: Use SQLite + FTS5 with Drizzle ORM for all environments.

**Rationale**:
- This is an internal tool for ~10-50 developers — SQLite handles this scale effortlessly
- FTS5 provides built-in full-text search without additional infrastructure (no Elasticsearch needed)
- Zero database configuration — a single file that persists via Docker volume
- Drizzle ORM is lightweight, type-safe, and has excellent SQLite/FTS5 support
- No need for PostgreSQL complexity (connection pooling, separate server process, migrations server)

**Alternatives Considered**:
- PostgreSQL + pg_trgm: Would provide similar search but requires running a separate database server, adding deployment complexity.
- Better-sqlite3 + hand-written SQL: Viable but Drizzle provides type safety and schema migration support.

---

### R-003: Monorepo Structure — npm Workspaces

**Context**: The project has three packages: shared types, server, and client. Need a monorepo tool.

**Decision**: npm workspaces with three packages: `packages/shared`, `packages/server`, `packages/client`.

**Rationale**:
- npm workspaces are built into npm — no additional tooling (Turborepo, Nx, Lerna) needed
- Three packages is well within the constitution's "max 4 projects" guideline
- `packages/shared` provides shared TypeScript types used by both server and client
- Standard `npm install`, `npm run build`, `npm test` commands work across all packages

**Alternatives Considered**:
- Turborepo: Adds caching and task orchestration but unnecessary overhead for 3 packages.
- Single package with embedded frontend build: Loses type sharing and clean separation.

---

### R-004: Testing Framework — Vitest + Playwright

**Context**: Constitution specifies xUnit + Testcontainers + Playwright. Since we're using TypeScript, we need TypeScript-native alternatives.

**Decision**: Vitest (unit + integration) + Playwright (E2E).

**Rationale**:
- Vitest is the TypeScript-native test runner, compatible with Vite and ESM
- Supertest for integration testing of Express API routes with real SQLite (`:memory:`)
- Playwright for E2E testing of full user flows (browse, search, submit)
- No Testcontainers needed — SQLite `:memory:` provides instant integration test databases

**Alternatives Considered**:
- Jest: Heavier config, slower with Vite/ESM. Vitest is the modern successor.
- Mocha + Chai: More configuration, less integrated with modern tooling.

---

### R-005: Authentication — Microsoft Entra ID OAuth 2.0

**Context**: Spec requires Microsoft Entra ID (Azure AD) SSO. Constitution also mandates MSAL.

**Decision**: `@azure/msal-node` (backend) + `@azure/msal-browser` (frontend) with HTTP-only session cookies.

**Rationale**:
- Matches the team's existing Microsoft identity infrastructure
- Session cookies (not JWTs) for simplicity — server-side sessions stored in SQLite
- MSAL handles the OAuth 2.0 authorization code flow with PKCE
- Auth required only for write operations (submissions, admin); browsing is unauthenticated

**Alternatives Considered**:
- API key auth: Simpler but less secure, no SSO integration.
- Passport.js with generic OAuth: More flexible but loses Microsoft-specific optimizations.

---

### R-006: Frontend Framework — React 19 + Vite 6 + Shadcn/ui

**Context**: Both constitution and spec agree on React + Vite + Tailwind + Shadcn/ui.

**Decision**: React 19, Vite 6, TypeScript 5, Tailwind CSS 4, Shadcn/ui, TanStack Query 5, React Router 7.

**Rationale**:
- Constitution and spec are fully aligned here — no conflict
- Shadcn/ui provides accessible, customizable components matching the constitution's component hierarchy requirements
- TanStack Query handles server state management with caching and background refetching
- `react-markdown` + `rehype-highlight` for rendering SKILL.md and reference documentation
- `@uiw/react-md-editor` for the submission form's markdown editor with live preview

---

### R-007: Git Sync Strategy — Octokit via GitHub REST API

**Context**: Spec requires reading marketplace.json + plugin files from GitHub and creating branches/PRs for submissions.

**Decision**: Octokit for all GitHub API interactions. No local Git clone.

**Rationale**:
- Octokit provides a typed, well-maintained GitHub REST API client
- Reading files directly via API avoids needing a local clone (simpler deployment)
- Creating branches + writing files + opening PRs via API is fully supported
- Conditional requests (ETag/If-Modified-Since) help with rate limit management

**Alternatives Considered**:
- Local Git clone + simple-git: More complex, requires Git binary in container, disk space for clone.
- GitHub GraphQL API: More efficient queries but REST API is sufficient and better documented for Octokit.

---

### R-008: Deployment — Docker Single Container

**Context**: Spec requires containerized deployment with persistent storage.

**Decision**: Multi-stage Dockerfile (build frontend → build backend → production image). Single container, single port (4000). Express serves built Vite frontend as static files in production.

**Rationale**:
- Single container simplifies deployment and operations
- SQLite database persists via Docker volume mount
- Multi-stage build keeps production image small (Alpine-based)
- Express serves both API and static frontend files — no separate nginx needed

**Alternatives Considered**:
- Separate frontend/backend containers: More complex orchestration for an internal tool.
- Kubernetes deployment: Overkill for single-instance internal app.
