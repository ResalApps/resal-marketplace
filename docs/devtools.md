# Devtools

Developer productivity tools for Resal engineering workflows.

## Table of Contents

- [Overview](#overview)
- [Skills](#skills)
  - [pr-review](#pr-review)
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
| **Bundled skills** | 1 |
| **Skill name** | `pr-review` |
| **Slash command** | `/devtools:pr-review` |
| **Triggers on** | "address PR comments", "process review feedback", "resolve PR threads", "handle reviewer feedback" |

## Skills

### pr-review

Processes review feedback on a GitHub pull request. The skill gathers unresolved review threads, classifies each comment as valid, invalid, or needing user input, presents a plan, applies approved fixes, posts replies where needed, pushes changes, and resolves addressed threads.

Use it when you have a PR URL, PR number, or `owner/repo#number` and want to systematically handle reviewer feedback before merging.

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

Manual command:

```
/devtools:pr-review ResalApps/example-repo#123
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
        +-- SKILL.md
```

## Example Session

```
User: Address the comments on ResalApps/resal-marketplace#6
Claude: I will gather the review threads, classify each comment, and show you a fix/reply plan before changing anything.
```
