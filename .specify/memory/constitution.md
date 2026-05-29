<!--
  ╔══════════════════════════════════════════════════════════════╗
  ║                SYNC IMPACT REPORT                           ║
  ╠══════════════════════════════════════════════════════════════╣
  ║ Version change: 0.0.0 → 1.0.0 (MAJOR — initial ratification)║
  ║                                                              ║
  ║ Modified principles: N/A (initial creation)                  ║
  ║ Added sections:                                              ║
  ║   • I. Clean Code Architecture                               ║
  ║   • II. Code Reuse (DRY)                                     ║
  ║   • III. Simplicity (KISS)                                   ║
  ║   • IV. Test-First Discipline                                ║
  ║   • V. Reusable UI Components                                ║
  ║   • VI. Server-Side Data Operations                          ║
  ║   • VII. Documentation as Code                               ║
  ║   • Technology Stack (Section 2)                             ║
  ║   • Development Workflow (Section 3)                         ║
  ║   • Governance                                               ║
  ║                                                              ║
  ║ Removed sections: N/A                                        ║
  ║                                                              ║
  ║ Templates requiring updates:                                 ║
  ║   • .specify/templates/plan-template.md     ✅ compatible    ║
  ║   • .specify/templates/spec-template.md      ✅ compatible    ║
  ║   • .specify/templates/tasks-template.md     ✅ compatible    ║
  ║                                                              ║
  ║ Follow-up TODOs: None                                        ║
  ╚══════════════════════════════════════════════════════════════╝
-->

# Resal Marketplace Web App Constitution

## Core Principles

### I. Clean Code Architecture

Every feature MUST follow Clean Code architecture with strict layer
separation. The system is organized into concentric layers where
dependencies point inward only:

- **Domain Layer** (innermost): Entities, value objects, domain
  exceptions, and interfaces. Zero external dependencies. Pure C#
  with no framework references.
- **Application Layer**: Use cases (CQRS handlers via MediatR),
  DTOs, validation, and interfaces for infrastructure. Depends only
  on the Domain layer.
- **Infrastructure Layer**: EF Core DbContexts, GitHub API clients
  (Octokit), external service integrations, file system access.
  Implements interfaces defined in Application. Depends on
  Application + Domain.
- **Presentation Layer** (outermost): API controllers, SignalR hubs,
  middleware. Depends on Application only — never on Infrastructure
  directly (use DI registration).
- **Frontend**: React component hierarchy mirrors backend structure.
  Hooks for data fetching, services for API calls, shared types from
  OpenAPI-generated clients.

**Rationale**: Layered architecture ensures testability at every
boundary. Domain logic is isolated from infrastructure concerns,
enabling free substitution of databases, APIs, or UI frameworks
without touching business rules.

### II. Code Reuse (DRY)

No duplicated logic is permitted anywhere in the codebase.

- **Shared Kernel**: Common types, guard clauses, extension methods,
  and constants live in a dedicated `SharedKernel` project referenced
  by all layers.
- **Reuse Before Create**: Before writing any new utility, component,
  or service, the developer MUST search the existing codebase. If a
  partial match exists, extend it rather than duplicate it.
- **Cross-Project Sharing**: Backend DTOs map to frontend TypeScript
  types via OpenAPI code generation (`NSwag` or `Kiota`). Never
  manually maintain parallel type definitions.
- **Component Library**: All reusable UI elements (buttons, tables,
  forms, modals, badges) MUST be created as Shadcn/ui components in
  a shared `components/ui/` directory. No one-off styled elements
  in page-level code.
- **Abstraction for Repeated Patterns**: If a pattern appears three
  times, extract it into a shared abstraction (base class, generic
  repository, custom hook, or HOC).

**Rationale**: Duplication leads to divergence. When a bug is fixed
in one copy but not the other, the system becomes unreliable. DRY
enforces a single source of truth for every concept.

### III. Simplicity (KISS)

Every implementation MUST be the simplest solution that correctly
satisfies the requirements. Complexity requires explicit
justification.

- **No Premature Abstraction**: Do not create interfaces, base
  classes, or generic solutions for problems that currently have
  exactly one implementation. Wait until the second use case
  emerges, then refactor (Rule of Three).
- **YAGNI Enforcement**: Features, configuration options, and
  extensibility points MUST NOT be added "just in case." Add them
  when a concrete requirement demands it.
- **Minimal Dependencies**: Prefer built-in .NET and React APIs over
  third-party packages. Every new NuGet/npm dependency MUST be
  justified in a PR comment explaining why the built-in alternative
  is insufficient.
- **Flat Over Nested**: Prefer flat file structures over deep
  directory hierarchies. A controller file belongs in
  `Controllers/`, not `Controllers/V2/Internal/Specialized/`.
- **Readability First**: Code is read far more often than written.
  Optimize for the reader: clear names, short methods (<30 lines),
  single-responsibility functions, and meaningful comments only
  where intent is non-obvious.

**Rationale**: Complexity is the enemy of maintainability. Every
unnecessary abstraction, dependency, or configuration option
increases the cognitive load on future developers and the surface
area for bugs.

### IV. Test-First Discipline

Testing is non-negotiable. Every feature MUST be validated through
a multi-layered testing strategy.

- **Unit Tests (xUnit)**: Every Application layer use case, Domain
  entity method, and Infrastructure service method MUST have unit
  tests. Minimum 80% code coverage on Application + Domain layers.
- **Integration Tests (Testcontainers)**: Every repository, database
  query, and external API interaction MUST be tested using
  Testcontainers for real containerized dependencies (PostgreSQL,
  Redis, etc.). No mocked database contexts.
- **E2E Tests (Playwright)**: Every user-facing workflow (browse
  catalog, search plugins, view detail, submit plugin) MUST have
  at least one Playwright E2E test covering the happy path.
- **Test Naming**: `{Method}_{Scenario}_{ExpectedResult}`.
  Example: `SearchPlugins_WithInvalidQuery_ReturnsEmptyList`.
- **Arrange-Act-Assert**: All tests follow the AAA pattern with
  clear section comments.
- **Test Data**: Use `AutoFixture` or builder patterns for test
  data generation. No hardcoded magic values in test assertions.

**Rationale**: Tests are executable specifications. They document
behavior, catch regressions, and enable fearless refactoring.
Testcontainers ensure integration tests reflect real runtime
conditions.

### V. Reusable UI Components

The frontend MUST be built from a library of reusable, composable
components — not page-specific monoliths.

- **Shadcn/ui Foundation**: All base UI primitives (Button, Input,
  Dialog, Table, etc.) come from Shadcn/ui. Extend, do not replace.
- **Component Hierarchy**:
  - `components/ui/` — Shadcn/ui primitives (unmodified)
  - `components/shared/` — Composed reusable components built from
    primitives (DataTable, SearchBar, TagFilter, MarkdownViewer)
  - `components/features/` — Feature-specific compositions using
    shared components (PluginCard, SkillDetail, SubmissionWizard)
  - `pages/` — Page layouts that compose feature components
- **Props Interface**: Every component MUST have a TypeScript
  interface for its props. No `any` types. Use discriminated unions
  for variant props.
- **Controlled Components**: All form components MUST be controlled
  (value + onChange). Uncontrolled components are forbidden.
- **Storybook (Recommended)**: Shared components SHOULD have
  Storybook stories for visual documentation and isolated testing.

**Rationale**: Reusable components reduce duplication, enforce visual
consistency, and accelerate feature development. A well-maintained
component library is a force multiplier for the entire team.

### VI. Server-Side Data Operations

All data tables in the application MUST perform ordering, sorting,
searching, and pagination on the server side. No client-side
filtering of large datasets.

- **DataTable Component**: A single reusable `DataTable` React
  component handles all tabular data display. It accepts:
  - `columns` — Column definitions with sort indicators
  - `data` — Current page of data
  - `pagination` — Page number, page size, total count
  - `onSort`, `onSearch`, `onPageChange` — Server callback props
- **API Contract**: Every list endpoint MUST accept standard query
  parameters:
  - `?page=1` — Page number (1-based)
  - `?pageSize=20` — Items per page
  - `?sortBy=Name` — Sort field name (PascalCase matches API DTO)
  - `?sortOrder=asc|desc` — Sort direction
  - `?search=keyword` — Full-text search query
  - `?tags[]=deployment&tags[]=infra` — Tag filter array
- **Response Envelope**: All paginated endpoints MUST return:
  ```json
  {
    "data": [...],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "totalCount": 42,
      "totalPages": 3
    }
  }
  ```
- **No Client-Side Pagination**: Data sets exceeding 50 records
  MUST NOT be loaded entirely into the browser. Server-side
  pagination is mandatory.
- **Debounced Search**: Search inputs MUST debounce API calls
  (300ms minimum). No API call on every keystroke.

**Rationale**: Server-side operations scale with data growth,
reduce client memory usage, and provide consistent response times
regardless of dataset size.

### VII. Documentation as Code

All code MUST be well-documented. Documentation is a first-class
deliverable, not an afterthought.

- **XML Doc Comments**: Every public C# class, method, property,
  and interface MUST have XML documentation comments (`/// <summary>`).
  This includes controllers, services, entities, and DTOs.
- **JSDoc/TSDoc**: Every exported TypeScript function, interface,
  and React component MUST have TSDoc comments describing purpose
  and parameters.
- **README per Project**: Every project in the solution MUST have
  a `README.md` explaining its purpose, dependencies, and how to
  run/test it locally.
- **API Documentation**: Swagger/OpenAPI spec is auto-generated
  from controller XML comments and annotations. The spec MUST be
  browsable at `/swagger` in development.
- **Architecture Decision Records**: Significant technical decisions
  (framework choices, data model changes, integration patterns)
  MUST be documented in `docs/adr/` using the ADR format.
- **Inline Comments**: Use inline comments only to explain WHY,
  never WHAT. The code itself explains what it does.

**Rationale**: Undocumented code is unmaintainable code. Future
developers (including your future self) need context to make safe
changes. Auto-generated API docs stay in sync with code.

## Technology Stack

The following technology choices are binding for this project.

### Backend

| Layer | Technology | Version |
|---|---|---|
| **Runtime** | .NET SDK | 10.0 |
| **Orchestration** | .NET Aspire | Latest (compatible with .NET 10) |
| **Web Framework** | ASP.NET Core Minimal APIs / Controllers | .NET 10 |
| **ORM** | Entity Framework Core | Latest compatible |
| **Database** | SQLite (dev) / PostgreSQL (production) | — |
| **Mediator** | MediatR | Latest |
| **Validation** | FluentValidation | Latest |
| **GitHub API** | Octokit | Latest |
| **Auth** | Microsoft Entra ID (Azure AD) | MSAL |
| **API Docs** | NSwag / Swashbuckle | Latest |

### Frontend

| Layer | Technology | Version |
|---|---|---|
| **Framework** | React | 19.x |
| **Build Tool** | Vite | 6.x |
| **Language** | TypeScript | 5.x |
| **Styling** | Tailwind CSS | 4.x |
| **UI Components** | Shadcn/ui | Latest |
| **State Management** | TanStack Query | 5.x |
| **Routing** | React Router | 7.x |
| **HTTP Client** | Fetch API + generated client | — |
| **Markdown** | react-markdown + rehype-highlight | Latest |

### Testing

| Layer | Technology | Purpose |
|---|---|---|
| **Unit** | xUnit + NSubstitute | Domain, Application, Infrastructure |
| **Integration** | Testcontainers (dotnet) | Repository, DbContext, GitHub API |
| **E2E** | Playwright | Full user workflow tests |
| **Coverage** | coverlet.collector | Code coverage reporting |

### Infrastructure

| Component | Technology |
|---|---|
| **Containerization** | Docker + docker-compose |
| **Orchestration** | .NET Aspire AppHost |
| **CI/CD** | GitHub Actions |
| **Auth Provider** | Microsoft Entra ID |

## Development Workflow

### Branch Strategy

- `main` — Production-ready code. Protected. Requires PR + review.
- `feature/{ticket}-{description}` — Feature branches from `main`.
- `fix/{ticket}-{description}` — Bug fix branches from `main`.
- `plugin/{name}-{date}` — Auto-generated branches for plugin
  submissions via the marketplace API.

### Code Review Gates

Every PR MUST pass these checks before merge:

1. **Build** — `dotnet build` and `npm run build` both succeed.
2. **Tests** — All unit, integration, and E2E tests pass.
3. **Constitution Compliance** — PR author self-certifies
   compliance with all seven principles.
4. **No `any` Types** — TypeScript strict mode. No `any` escapes.
5. **XML Docs** — All new public members have XML doc comments.
6. **No Hardcoded Secrets** — Zero credentials in source code.

### Local Development

1. Clone the repository.
2. Run `dotnet restore` and `npm install`.
3. Copy `.env.example` to `.env` and fill in values.
4. Run `dotnet aspire run` to start all services via Aspire.
5. Run `npm run dev` for frontend hot-reload.
6. Access Swagger at `http://localhost:4000/swagger`.

### Commit Messages

Follow Conventional Commits:

```
type(scope): description

feat(api): add plugin search endpoint with FTS5
fix(ui): resolve DataTable pagination off-by-one error
docs(readme): add local development setup instructions
test(integration): add Testcontainers tests for PluginRepository
refactor(domain): extract Plugin entity from PluginEntity value object
```

## Governance

- **Constitution Supremacy**: This constitution takes precedence
  over individual preferences. When in doubt, follow these
  principles.
- **Amendment Process**: Any principle change MUST be proposed as a
  PR to this file, include a rationale, and be approved by at least
  one other team member.
- **Version Policy**: Semantic versioning (MAJOR.MINOR.PATCH).
  - MAJOR: Principle removed or fundamentally redefined.
  - MINOR: New principle added or existing one materially expanded.
  - PATCH: Clarifications, wording fixes, non-semantic refinements.
- **Compliance Review**: Every sprint retrospective MUST include a
  constitution compliance check. Violations are tracked as tech debt.
- **Complexity Justification**: Any deviation from KISS or DRY MUST
  include a written justification in the PR describing why the
  simpler alternative was insufficient.
- **Runtime Guidance**: For detailed implementation guidance beyond
  these principles, refer to `docs/marketplace-web-app-plan.md`.

**Version**: 1.0.0 | **Ratified**: 2026-04-02 | **Last Amended**: 2026-04-02
