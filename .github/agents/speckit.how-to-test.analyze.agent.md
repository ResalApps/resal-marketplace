---
description: Analyze Spec Kit plan/tasks for missing E2E, screenshot-capture, and
  API sample tasks required before How-To-Test documentation.
---


<!-- Extension: how-to-test -->
<!-- Config: .specify/extensions/how-to-test/ -->
# Analyze How-To-Test Coverage

Review the active Spec Kit feature before implementation and make sure `tasks.md` contains the E2E,
UI screenshot-capture, API sample, and documentation-readiness work needed for the later
How-To-Test manual.

Recommended lifecycle phase: `after_tasks`. At this point `spec.md`, `plan.md`, and `tasks.md`
exist, but implementation has not started, so missing tests can be added before developers begin.

Alternative phase: `before_implement` if a team prefers a final gate immediately before coding. Do
not use `after_implement` as the primary hook for this command because by then missing E2E work is
usually rework.

## User Input

```text
$ARGUMENTS
```

Optional flags:

- `--feature <path>` - override feature directory detection, e.g. `specs/006-user-management`.
- `--report-only` - report missing tasks without editing `tasks.md`.
- `--phase after_tasks|before_implement|manual` - record the user's selected lifecycle phase in the
  report. The recommendation remains `after_tasks`.

## Behavior Overview

```text
resolve feature -> load artifacts -> map impacted projects -> audit tasks -> patch tasks.md -> report
```

## Instructions

### 1. Resolve the active feature

- If `--feature` is supplied, use it.
- Otherwise read `.specify/feature.json` and use `feature_directory`.
- If feature detection fails, use the most recently modified directory under `specs/` only when it is
  unambiguous. If still ambiguous, ask the user for the feature path.

Required files:

- `<feature_dir>/spec.md`
- `<feature_dir>/plan.md`
- `<feature_dir>/tasks.md`

Optional but important files:

- `<feature_dir>/quickstart.md`
- `<feature_dir>/data-model.md`
- `<feature_dir>/contracts/*`
- `<feature_dir>/research.md`
- `.github/memory/project-memory.md`
- Recent git diff and changed files, if available

### 2. Load project memory and inspect the workspace

- Read `.github/memory/project-memory.md` when it exists.
- If it is missing, create a minimal scan note or tell the user to run the `how-to-test` skill's
  initialization pass. Do not block this command if enough feature context exists.
- Identify impacted projects from the feature plan, task file paths, contracts, routes, menu names,
  UI screens, mobile flows, backend endpoints, and changed files.
- Pay special attention to web and mobile frontends. Detect Playwright, Cypress, Detox, Maestro,
  Appium, Expo, React Native, Vite, Next.js, and React markers when present.

### 3. Build the documentation coverage matrix

For each user story and scenario in `spec.md`, determine whether the later How-To-Test manual will
need one or more of the following:

- Web E2E test for the main user journey.
- Mobile E2E test for the main user journey.
- Screenshot-capture test for each screen, form, dialog, menu entry, validation state, permission
  state, empty state, error state, loading state, and expected result.
- Architecture diagram generation/export task when the feature changes or clarifies service
  boundaries, infrastructure, integrations, data flow, security zones, deployment topology, or major
  component responsibilities.
- Process-flow diagram generation/export task when the feature changes or clarifies a user journey,
  approval flow, automation sequence, job lifecycle, integration sequence, validation flow, or
  exception path.
- API contract or integration test that proves request and response bodies for API-only scenarios.
- Fixture or mock data task for deterministic screenshots and stable examples.
- Accessibility smoke test for generated manual pages and UI screenshots.
- Index/navigation update for the relevant project How-To-Test documentation.

Treat these as missing coverage when tasks are absent or too vague:

- A UI user story has no named E2E task.
- A new route, menu item, form, or validation flow has no screenshot-capture task.
- Architecture-impacting work has no `architecture-diagram` HTML + PNG export task.
- Workflow/process-impacting work has no `process-flow-diagram` HTML + PNG export task.
- A backend/API-only scenario has no request/response sample validation task.
- A mobile-accessible scenario has only a web E2E task.
- A scenario is intentionally not available on mobile but no task records that limitation in the
  manual.
- A test task says only "add tests" without path, runner, scenario, or expected result.

### 4. Patch `tasks.md`

Unless `--report-only` was supplied, update `tasks.md`.

Rules:

- Preserve the existing Spec Kit task format:
  `- [ ] T### [P?] [US#?] Description with file path`
- Preserve existing task order and content.
- Do not duplicate existing E2E, screenshot, diagram, API sample, or documentation tasks.
- Continue numbering from the highest existing `T###`.
- Put user-story-specific gaps in that user story's `### Tests` section when one exists. If the
  story has no tests section, create `### How-To-Test readiness tasks` inside that story phase.
- Put cross-project or cross-cutting gaps in the final Polish/Cross-Cutting phase.
- Mark tasks `[P]` only when they write different files and do not depend on each other.
- Include exact target paths. If a path is inferred from plan structure, use the planned project
  root and keep it specific.
- If replacing a previous readiness block, refresh it idempotently. Prefer a markdown block with
  these markers when you create a dedicated section:

```markdown
<!-- how-to-test-prepare:start -->
### How-To-Test readiness tasks

- [ ] T123 [P] [US1] Add Playwright E2E test for ...

<!-- how-to-test-prepare:end -->
```

Task wording examples:

```markdown
- [ ] T041 [P] [US1] Add Playwright E2E test for admin password reset happy path in frontend/e2e/user-management/password-reset.spec.ts
- [ ] T042 [P] [US1] Add screenshot capture for User Management password reset states in frontend/e2e/how-to-test/user-management-password-reset.capture.spec.ts
- [ ] T043 [P] [US1] Add API request/response fixture coverage for POST /api/users/{id}/password-reset in backend/tests/contracts/user-management-password-reset.test.ts
- [ ] T044 [P] [US1] Generate process-flow-diagram HTML and PNG assets for the password reset workflow in frontend/public/how-to-test/assets/user-management/diagrams/user-management-password-reset-process-flow.html
- [ ] T045 [US1] Update User Management How-To-Test documentation index under frontend/public/how-to-test/features/user-management/index.html
```

### 5. Report

Report:

- Feature path audited.
- Selected lifecycle phase and recommendation. If the user did not select a phase, state
  `after_tasks` as the recommendation.
- Impacted projects.
- Missing coverage found.
- Tasks added, with task IDs.
- If `--report-only` was used, list the tasks that should be added.
- Any unresolved ambiguity, especially parent feature routing or mobile availability.

Do not claim tests exist unless they are present in `tasks.md` or the workspace. Do not invent
screens, endpoints, or request/response bodies. Ground every task in the spec, plan, contracts, or
project structure.

## Quality Bar

After this command runs, a developer should be able to implement the feature and its E2E/API
coverage in one pass. The later `how-to-test` documentation step should not discover that a screen,
mobile state, validation path, or API sample was never tested or captured.