---
description: "Generate the feature CHANGELOG + plain-English feature-details doc, then create or update the PR description with the feature details under a review heading."
---

# Generate a Detailed PR

Turn the work of a completed Spec Kit feature into two reviewer-facing artifacts and a rich
pull-request description:

1. A **CHANGELOG** — a precise, technical record of what shipped.
2. A **feature-details document** — a plain-English, product-manager-friendly explanation of the
   feature, its role, the scenarios it supports (with examples and diagrams).

…then **create or update the pull request** for the current branch so the feature-details content
appears in its description under the heading **"What have been developed and how to review it"**.

This command is **idempotent and context-aware**: run it as an `after_implement` hook (when the PR
may not exist yet) or manually at PR time — it converges on the same result and never duplicates.

## User Input

$ARGUMENTS

Optional flags the user may pass:

- `--no-pr` — generate/refresh the docs only; do not touch any pull request.
- `--create-pr` — if no PR exists for the branch, create one without asking first.
- `--feature <path>` — override feature directory detection (e.g. `specs/006-...`).
- `--heading "<text>"` — override the PR section heading (default: *What have been developed and how to review it*).

## Behavior Overview

```
resolve feature  ->  gather ground truth  ->  write docs/<feature>/  ->  handle the PR  ->  report
```

## Instructions

### 1. Resolve the active feature

- Read `.specify/feature.json` and take `feature_directory` (e.g. `specs/006-finance-settlement-ledger`).
  If `--feature` was supplied, use that instead.
- Derive the **feature slug** = the final path segment (e.g. `006-finance-settlement-ledger`).
- If `.specify/feature.json` is missing or unreadable, fall back to the current git branch name and
  the most recently modified directory under `specs/`; if still ambiguous, ask the user which feature.

### 2. Gather ground truth (never invent)

Read whatever exists for the feature so all generated content traces to real artifacts:

- `<feature_dir>/spec.md` (user stories, requirements, acceptance scenarios, edge cases, scope, assumptions, open questions)
- `<feature_dir>/plan.md`, `data-model.md`, `tasks.md`, `quickstart.md`, `research.md`, `contracts/*`
- Any existing `<feature_dir>/CHANGELOG.md` or `progress.yml` (reuse delivery facts: tests, coverage, commits, issue/PR numbers)
- `git log` for the branch (commit subjects, scope)

If something is unknown, **omit it** — do not fabricate test counts, coverage, issue numbers, or behavior.

### 3. Write the two documents under `docs/<feature-slug>/`

Create the folder if needed. The folder name **matches the spec folder name** so it can drop into a
wiki cleanly.

#### 3a. `docs/<feature-slug>/CHANGELOG.md`

A [Keep a Changelog](https://keepachangelog.com/)–style technical record. Header block with spec
path, branch, tracking issue/PR (if known), and what it builds on. Then a single dated version
section grouping changes under: **Added**, **Changed**, **Architecture & boundaries** (if relevant),
**Migration** (if relevant), **Tests & quality**, **Scope (not in this phase)**, **Open items**.
Be concrete and accurate; map functional requirements / acceptance criteria to what shipped.

#### 3b. `docs/<feature-slug>/<Feature>-Explained.md`

The **plain-English, business/PM-facing narrative**. Audience: a product manager or commercial
stakeholder, *not* an engineer. Friendly and descriptive; light humor and real-world analogies are
welcome when they aid understanding. Avoid jargon; define any unavoidable term. Use this proven
structure (scale each section to the feature — skip what doesn't apply):

1. **Title + one-line subtitle** and a *one-paragraph version* (the whole feature in ~4 sentences).
2. **Why we needed this ("so what")** — the business problem, ideally with an analogy.
3. **The building blocks in human words** — a small table mapping each core concept to "what it
   really is" and a real-world analogy.
4. **What this feature can do — the scenarios, with examples** — the heart of the doc. One numbered
   scenario per capability, each with: a short *Story* (concrete, named actors, real numbers reused
   consistently), what the system does, and a **Mermaid diagram** where a flow or lifecycle helps
   (`sequenceDiagram` for flows, `stateDiagram-v2` for lifecycles, `flowchart` for actor/role maps).
   Cover the happy paths **and** the guardrails (rejections, immutability, idempotency, fail-closed).
5. **Who does what** — the cast of actors and their boundaries.
6. **What this phase deliberately does NOT do** — scope boundaries, to set expectations.
7. **Caveats / pending decisions** — anything flagged as baseline-pending-sign-off or an open question.
8. **How confident should you be?** — summarize tests/coverage/quality in plain terms (only if known).
9. **Glossary** — plain meanings of any terms that appeared.

Footer: link back to `CHANGELOG.md` and the `specs/<feature-slug>/` spec.

Prefer **Mermaid** over inline SVG — it renders inline in GitHub/Azure DevOps/most wikis and stays
editable. Keep Mermaid syntax valid (quote labels containing punctuation; one node/edge per line).

> Quality bar: a reader who has never seen the code should finish the feature-details doc knowing
> what the feature is, why it exists, every scenario it supports, and exactly what's out of scope.

### 4. Handle the pull request

Unless `--no-pr` was passed:

- Detect the PR for the current branch:
  `gh pr view --json number,url,body` (or `gh pr list --head <branch> --json number,url,body`).
- Build the **section content**: the heading (default **`## What have been developed and how to
  review it`**), then the full feature-details narrative (the body of `<Feature>-Explained.md`),
  wrapped in idempotency markers:

  ```
  <!-- speckit-pr:start -->
  ## What have been developed and how to review it

  …feature-details content…
  <!-- speckit-pr:end -->
  ```

- **If a PR exists:**
  - If the body already contains `<!-- speckit-pr:start -->`…`<!-- speckit-pr:end -->`, **replace
    everything between the markers** (preserve all other PR body content above/below). Never append
    a second copy.
  - Otherwise, append the marked section to the end of the existing body (keep the existing body intact).
  - Apply with `gh pr edit <number> --body-file <tmpfile>`.
- **If no PR exists:**
  - With `--create-pr`, create it: `gh pr create --base <default-branch> --head <branch>
    --title "<feature title>" --body-file <tmpfile>` (body = a short summary + the marked section).
  - Without `--create-pr`, **ask** the user whether to create the PR now. If they decline, write the
    docs only and tell them to re-run (or run `/speckit-pr-generate`) once the PR exists.

### 5. Report

Summarize: the doc paths written, whether the PR was created or updated (with its URL), and any
follow-ups (e.g. "no PR yet — re-run after opening one"). State test/coverage figures only if you
sourced them from real artifacts.

## Idempotency

Fixed doc paths + marker-delimited PR section mean the hook-run and any manual re-run converge on the
same result. Re-running refreshes the docs and replaces (never duplicates) the PR section.

## Graceful Degradation

- **No `gh` / not authenticated / no remote:** write the docs, skip PR handling, and tell the user the
  PR step was skipped (and why).
- **Not a git repo:** still generate the docs from the spec artifacts.
- **No spec artifacts found:** ask the user for the feature directory rather than guessing content.
- **Detached/odd branch state:** report it and skip PR handling rather than creating a PR on the wrong base.
