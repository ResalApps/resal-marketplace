# Devtools

Developer productivity tools for Resal engineering workflows.

## Table of Contents

- [Overview](#overview)
- [Skills](#skills)
  - [pr-review](#pr-review)
  - [resal-standards-review](#resal-standards-review)
  - [speckit-pr-generate](#speckit-pr-generate)
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
| **Bundled skills** | 3 |
| **Skill names** | `pr-review`, `resal-standards-review`, `speckit-pr-generate` |
| **Slash commands** | `/devtools:pr-review`, `/devtools:resal-standards-review`, `/devtools:speckit-pr-generate` |
| **Triggers on** | "address PR comments", "process review feedback", "resolve PR threads"; "review against Resal standards", "compliance report", "standards audit", "gaps report", "remediation plan"; "generate a detailed PR", "write the PR description", "document this feature for review" |

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

### speckit-pr-generate

Wraps up a finished feature by producing two reviewer-facing documents and filling in the pull
request description. It writes:

- `docs/<feature-slug>/CHANGELOG.md` — a technical, Keep-a-Changelog-style record of what shipped.
- `docs/<feature-slug>/<Feature>-Explained.md` — a plain-English, product-manager-friendly narrative
  of the feature (its purpose, the scenarios it supports with concrete examples, and Mermaid diagrams).

It then creates or updates the PR for the current branch, injecting the feature-details narrative
under the heading **"What have been developed and how to review it"** between idempotency markers, so
re-running refreshes the section instead of duplicating it.

| Behavior | Detail |
|---|---|
| **Feature detection** | Reads `.specify/feature.json` in Spec Kit projects; falls back to the git branch / a `docs\|specs` folder elsewhere, and asks if ambiguous. |
| **PR handling** | Updates an existing PR; offers to create one (`--create-pr` to skip the prompt). `--no-pr` writes docs only. |
| **Grounding** | Reads `spec.md`/`plan.md`/`data-model.md`/`tasks.md`/`git log`; never fabricates test counts, coverage, or issue numbers. |
| **Idempotent** | Fixed doc paths + marker-delimited PR section converge on re-run. |

This skill is the **portable twin of the `pr` Spec Kit extension** hosted in
[`extensions/pr/`](../extensions/) — same name, same behavior. Use the **extension** to wire it into
the Spec Kit `after_implement` lifecycle; use the **skill** for the slash command anywhere.

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
| "Generate a detailed PR for this feature" | speckit-pr-generate |
| "Write the PR description and a changelog for this branch" | speckit-pr-generate |
| "Document this feature for review" | speckit-pr-generate |

Manual commands:

```
/devtools:pr-review ResalApps/example-repo#123
/devtools:resal-standards-review
/devtools:speckit-pr-generate
/devtools:speckit-pr-generate --no-pr        # docs only
/devtools:speckit-pr-generate --create-pr    # also create the PR if none exists
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
    |   +-- SKILL.md
    |   +-- checks-core.md
    |   +-- checks-python.md
    |   +-- checks-dotnet.md
    |   +-- checks-react-web.md
    |   +-- checks-react-native.md
    |   +-- report-template.md
    |   +-- remedy-plan-template.md
    |   +-- standards/         (bundled prose: core + per-stack)
    +-- speckit-pr-generate/
        +-- SKILL.md
```

> The `speckit-pr-generate` skill is mirrored as the **`pr` Spec Kit extension** under
> [`extensions/pr/`](../extensions/) (installed with the `specify` CLI, not `/plugin`).

## Example Session

```
User: Address the comments on ResalApps/resal-marketplace#6
Claude: I will gather the review threads, classify each comment, and show you a fix/reply plan before changing anything.
```
