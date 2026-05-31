# Devtools

Developer productivity tools for Resal engineering workflows.

## Table of Contents

- [Overview](#overview)
- [Skills](#skills)
  - [pr-review](#pr-review)
  - [resal-standards-review](#resal-standards-review)
- [Installation](#installation)
- [How to Use](#how-to-use)
- [Workflow](#workflow)
- [Bundled Files](#bundled-files)
- [Example Session](#example-session)

---

## Overview

| | |
|---|---|
| **Plugin name** | `devtools` |
| **Bundled skills** | 2 |
| **Skill names** | `pr-review`, `resal-standards-review` |
| **Slash commands** | `/devtools:pr-review`, `/devtools:resal-standards-review` |
| **Triggers on** | "address PR comments", "process review feedback", "resolve PR threads"; "review against Resal standards", "compliance report", "standards audit", "gaps report", "remediation plan" |

## Skills

### pr-review

Processes review feedback on a GitHub pull request. The skill gathers unresolved review threads, classifies each comment as valid, invalid, or needing user input, presents a plan, applies approved fixes, posts replies where needed, pushes changes, and resolves addressed threads.

Use it when you have a PR URL, PR number, or `owner/repo#number` and want to systematically handle reviewer feedback before merging.

### resal-standards-review

Reviews/audits any Resal project against the **Resal Engineering Standards** and produces a severity-rated **Compliance & Gaps Report**. It **auto-detects the stack** from marker files and loads the matching rules:

| Marker | Stack | Rules loaded |
|---|---|---|
| `*.csproj` / `*.sln` | .NET | core + dotnet |
| `package.json` with `react-native`/`expo` | React Native | core + react-native |
| `package.json` with `react`/`next` (no RN) | React web | core + react-web |
| `pyproject.toml` / `app/` + FastAPI | Python | core + python |
| more than one marker | multi | core + each stack (per-stack report sections) |

Findings are rated **critical / high / medium / nice-to-have**. Two modes:
- **Full (default):** report → **asks which severity tiers** to include → generates a **Remedy Plan** for those tiers only.
- **Report-only:** say "report only" / "audit only" / "no remedy" to stop at the report (no questions, no plan).

The full prose standards (`core.md` + per-stack files) are bundled under `skills/resal-standards-review/standards/`; the skill's `checks-*.md` catalogs are self-sufficient even without them. The skill never edits target code — the remedy plan is a written plan unless you explicitly ask it to execute.

## Installation

Run this inside Claude Code:

```
/plugin install devtools@resal
```

Then run `/reload-plugins` if the plugin list does not update automatically.

## How to Use

Automatic trigger examples:

| Say this... | Skill activated |
|-------------|-----------------|
| "Address the comments on ResalApps/example#123" | pr-review |
| "Process this PR feedback: https://github.com/owner/repo/pull/123" | pr-review |
| "Resolve the review threads on PR 42" | pr-review |
| "Review this service against the Resal standards" | resal-standards-review |
| "Run a compliance and gaps report on ./ResalPay (report only)" | resal-standards-review |
| "Audit this app against our coding standards and give me a remediation plan" | resal-standards-review |

Manual commands:

```
/devtools:pr-review ResalApps/example-repo#123
/devtools:resal-standards-review
```

## Workflow

1. Gather PR metadata, diffs, review comments, review summaries, issue comments, and review thread IDs through `gh`.
2. Filter out already resolved, outdated, author-authored, or purely status-only comments.
3. Classify each substantive comment as valid, invalid, or needing user input.
4. Present a plan and wait for user approval before editing or posting replies.
5. Apply approved fixes, run targeted verification, commit, and push.
6. Post a summary comment and resolve addressed review threads.

## Bundled Files

```text
plugins/devtools/
+-- .claude-plugin/
|   +-- plugin.json
+-- README.md
+-- skills/
    +-- pr-review/
    |   +-- SKILL.md
    +-- resal-standards-review/
        +-- SKILL.md
        +-- checks-core.md
        +-- checks-python.md
        +-- checks-dotnet.md
        +-- checks-react-web.md
        +-- checks-react-native.md
        +-- report-template.md
        +-- remedy-plan-template.md
        +-- standards/         (bundled prose: core + per-stack)
```

## Example Session

```
User: Address the comments on ResalApps/resal-marketplace#6
Claude: I will gather the review threads, classify each comment, and show you a fix/reply plan before changing anything.
```
