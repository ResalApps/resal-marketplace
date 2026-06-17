# Devtools

Developer productivity tools for Resal engineering workflows.

## Included Skills

| Skill                    | Description                                                                                                                                                                                                                                                                                                                              |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pr-review`              | Process GitHub PR review comments, plan fixes or replies, apply approved changes, push, and resolve addressed threads.                                                                                                                                                                                                                   |
| `how-to-test`            | Generate (or update) an internal QA-facing **How-To-Test manual** for a completed feature — a self-contained HTML walkthrough of every user case, with Playwright screenshots (captured against mocked backend endpoints) for web pages and request/response samples for headless APIs. Supports single- and multi-project workspaces.                                                                                                                                                                                                                                                               |
| `resal-standards-review` | Review/audit any Resal project against the **Resal Engineering Standards**. Auto-detects the stack (Python/FastAPI, .NET, React web, or React Native), produces a severity-rated **Compliance & Gaps Report**, and — in full mode — asks which severity tiers to fix before generating a **Remedy Plan**. Supports **report-only** mode. |
| `speckit-pr-generate`    | Generate a technical **CHANGELOG** and a plain-English, PM-friendly **feature-details** doc under `docs/<feature>/`, then create or update the PR description with the feature details under **"What have been developed and how to review it"**. Works with or without Spec Kit; idempotent (re-runs refresh, never duplicate).         |

## Usage

Install from the Resal marketplace:

```
/plugin install devtools@resal
```

### pr-review

```
/devtools:pr-review ResalApps/example-repo#123
```

### how-to-test

```
/devtools:how-to-test generate a test Doc for the spec feature xx-xxx
```

### resal-standards-review

Ask Claude to review a project against the Resal standards, or invoke the skill directly:

```
/devtools:resal-standards-review            # then point it at a project path
```

- **Full mode (default):** report → asks which severity tiers (critical/high/medium/nice-to-have) → remedy plan.
- **Report-only:** say "report only" (or "audit only" / "no remedy") to stop at the report.
- The skill **auto-detects** the stack from marker files (`*.csproj`/`*.sln` → .NET, `package.json` + `react-native`/`expo` → React Native, `package.json` + `react`/`next` → React web, `pyproject.toml`/`app/` → Python) and loads the matching rules. Mixed-stack repos are reported per stack.

The full prose standards (`core.md` + per-stack files) are **bundled** with the skill under `skills/resal-standards-review/standards/`; the skill's `checks-*.md` catalogs are self-sufficient even without them.

### speckit-pr-generate

Run it when wrapping up a feature, before or after opening the PR:

```
/devtools:speckit-pr-generate                 # docs + create/update the PR description
/devtools:speckit-pr-generate --no-pr         # generate/refresh docs only
/devtools:speckit-pr-generate --create-pr     # also create the PR if none exists
```

- In **Spec Kit** projects it reads `.specify/feature.json` to find the feature; otherwise it falls
  back to the git branch / a `docs|specs` folder and asks if ambiguous.
- Writes `docs/<feature-slug>/CHANGELOG.md` and `docs/<feature-slug>/<Feature>-Explained.md`, then
  injects the feature-details narrative into the PR body under a marker-delimited section so re-runs
  refresh rather than duplicate.
- This skill is the portable twin of the **`pr` Spec Kit extension** hosted in this repo under
  [`extensions/pr/`](../../extensions/) — same name (`speckit-pr-generate`), same behavior. Use the
  extension when you want it wired into the Spec Kit `after_implement` lifecycle; use this skill when
  you just want the slash command anywhere.
