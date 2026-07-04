# Project Memory

Last scanned: 2026-07-04
Workspace root: `D:\Projects\Resal\resal-marketplace`

This memory file is maintained by the `how-to-test` workflow. It records the projects detected in
the workspace so feature documentation can be routed to the correct project and parent feature.

## Frontend Coverage Summary

- Web frontend implementation detected: no.
- Mobile frontend implementation detected: no.
- Planned frontend context exists in `specs/001-marketplace-web-app/`, `docs/marketplace-web-app-plan.md`, and `.specify/memory/constitution.md`, which describe a future React/Vite web application, but no `package.json`, Vite/Next config, React Native/Expo app, `android/`, or `ios/` project directory is currently present in this workspace.
- Reusable frontend routing context for later How-To-Test runs: planned web frontend at `packages/client`, public assets at `packages/client/public`, How-To-Test root at `packages/client/public/how-to-test`, screenshot runner `Playwright`, and dev URL `http://localhost:5173`.

## Frontend Project Inventory

| Project | Path | Status | Platform | Framework / Build Tool | Router / App Shell Evidence | Public / Assets Directory | How-To-Test Root | Screenshot Runner | Key Commands | Evidence Sources |
|---|---|---|---|---|---|---|---|---|---|---|
| Marketplace client | `packages/client` | planned/spec-only | Web frontend | React 19, Vite 6, TypeScript, Tailwind CSS 4, Shadcn/ui, TanStack Query 5 | Planned `src/main.tsx`, `src/App.tsx`, and pages `Catalog`, `PluginDetail`, `SkillDetail`, `Submit`, `MySubmissions`, `Admin` | `packages/client/public` | `packages/client/public/how-to-test` | Playwright | `npm run dev`, `npm run build`, `npm run test:e2e` | `specs/001-marketplace-web-app/plan.md`, `specs/001-marketplace-web-app/quickstart.md`, `specs/001-marketplace-web-app/research.md`, `docs/marketplace-web-app-plan.md`, `.specify/memory/constitution.md` |
| Mobile marketplace client | N/A | none detected | Mobile frontend | N/A | N/A | N/A | N/A | N/A | N/A | No React Native, Expo, `android/`, `ios/`, `metro.config.*`, `app.json`, or `app.config.*` markers found in the workspace. |

## Detected Projects

| Project | Path | Role | Detected Markers | Documentation / How-To-Test Notes |
|---|---|---|---|---|
| Resal Marketplace | `.` | Tooling marketplace and documentation registry | `.claude-plugin/marketplace.json`, `README.md`, `docs/`, `plugins/`, `extensions/`, `.specify/` | Workspace-level docs live in `docs/`. Workspace How-To-Test index should live at `how-to-test/index.html` when manuals are generated. |
| add-app-deployment plugin | `plugins/add-app-deployment` | Deployment and infrastructure automation tooling | `.claude-plugin/plugin.json`, `skills/add-app-deployment/SKILL.md`, deployment references | Role is deployment/infrastructure. Generate manuals under `plugins/add-app-deployment/how-to-test/` if this plugin is changed. |
| devtools plugin | `plugins/devtools` | Developer productivity, QA documentation, standards review, PR workflow tooling | `.claude-plugin/plugin.json`, `README.md`, `skills/pr-review/`, `skills/how-to-test/`, `skills/resal-standards-review/`, `skills/pr-generate-description/` | Role is tooling/documentation. How-To-Test and PR description generation can call illustration-tools to produce architecture/process HTML + PNG assets. |
| illustration-tools plugin | `plugins/illustration-tools` | Documentation visualization tooling | `.claude-plugin/plugin.json`, `skills/architecture-diagram/`, `skills/process-flow-diagram/`, HTML/SVG templates | Role is tooling/documentation. It produces source HTML and PNG visual assets for PR and How-To-Test docs, but is not a web app frontend. |
| report-publisher plugin | `plugins/report-publisher` | Report publishing workflow tooling | `.claude-plugin/plugin.json`, `README.md`, `skills/report-publisher-skill/` | Role is tooling/integration. Generate manuals under `plugins/report-publisher/how-to-test/` if changed. |
| Detailed PR Generator extension | `extensions/pr` | Spec Kit workflow extension for PR and feature documentation | `extension.yml`, `commands/speckit.pr.generate.md`, `README.md`, `CHANGELOG.md` | Role is workflow/documentation. Hook currently targets `after_implement`; generated feature docs include architecture/process diagram assets when relevant. |
| How-To-Test extension | `extensions/how-to-test` | Spec Kit workflow extension for QA How-To-Test manual generation and E2E/API/screenshot/diagram readiness | `extension.yml`, `commands/speckit.how-to-test.document.md`, `commands/speckit.how-to-test.analyze.md`, `README.md`, `CHANGELOG.md` | Role is QA workflow/testing documentation. Manual generation hook targets `after_implement`; readiness hook targets `after_tasks`, creates this project memory, and includes frontend/E2E/API/screenshot/diagram-readiness tasks. |
| PR Review Processor extension | `extensions/pr-review` | Spec Kit command for approval-gated GitHub PR review feedback processing | `extension.yml`, `commands/speckit.pr-review.process.md`, `README.md`, `CHANGELOG.md` | Role is PR workflow tooling. Command is manual because review comments exist after PR review, outside the normal implementation lifecycle. |
| Extension release tooling | `extensions/scripts` | Extension packaging and catalog release automation | `package.sh`, `release.py` | Role is release/deployment tooling for Spec Kit extensions. |
| GitHub workflow and Spec Kit agents | `.github` | CI, prompts, and Spec Kit agent instructions | `.github/workflows/`, `.github/agents/`, `.github/prompts/` | Role is workflow automation. Hook names currently include `before_specify`, `after_specify`, `before_plan`, `after_plan`, `before_tasks`, `after_tasks`, `before_implement`, and `after_implement`. |
| Marketplace Web App specification | `specs/001-marketplace-web-app` | Product/architecture specification package, no implementation code detected | `spec.md`, `plan.md`, `data-model.md`, `quickstart.md`, `contracts/`, `checklists/` | Describes a planned marketplace web app. Do not treat it as an implemented frontend until project marker files are added. |

## Scan Markers

- Implemented application project markers found: none (`package.json`, `vite.config.*`, `next.config.*`, `angular.json`, `app.json`, `app.config.*`, `metro.config.*`, `android/`, `ios/`, `*.csproj`, `*.sln`, `pyproject.toml`, `go.mod`, and `Cargo.toml` were not detected outside generated/vendor folders).
- Planned web frontend markers found in specs/docs: `packages/client/package.json`, `packages/client/vite.config.ts`, `packages/client/index.html`, `packages/client/src/main.tsx`, `packages/client/src/App.tsx`, `packages/client/src/pages/*`, React 19, Vite 6, Tailwind CSS 4, Shadcn/ui, TanStack Query 5, React Router, and Playwright.
- Spec Kit extension markers found: `extensions/pr/extension.yml`, `extensions/how-to-test/extension.yml`, `extensions/pr-review/extension.yml`.
- Claude plugin markers found: `.claude-plugin/marketplace.json` and four local plugin manifests under `plugins/*/.claude-plugin/plugin.json`.

## Maintenance Rules

- Re-scan before generating or updating a How-To-Test manual.
- Update this file when a new project marker appears, especially web or mobile frontend markers.
- Use this file to route documentation, but confirm against current changed files and feature artifacts.
- If a feature enhances an existing parent feature, update that parent documentation instead of creating a disconnected top-level feature.
