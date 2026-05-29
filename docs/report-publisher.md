# Report Publisher

Publish generated reports to the self-hosted Resal Report Portal.

## Table of Contents

- [Overview](#overview)
- [What It Does](#what-it-does)
- [Bundled Files](#bundled-files)
- [Prerequisites](#prerequisites)
- [How to Use](#how-to-use)
  - [Install the Plugin](#install-the-plugin)
  - [Trigger the Skill](#trigger-the-skill)
  - [Information You Will Need](#information-you-will-need)
- [Workflow](#workflow)
  - [Phase 1: Gather Report Details](#phase-1-gather-report-details)
  - [Phase 2: Choose Publish Command](#phase-2-choose-publish-command)
  - [Phase 3: Publish](#phase-3-publish)
  - [Phase 4: Verify and Troubleshoot](#phase-4-verify-and-troubleshoot)
- [Publishing Examples](#publishing-examples)
- [Security Defaults](#security-defaults)
- [Example Session](#example-session)

---

## Overview

| | |
|---|---|
| **Plugin name** | `report-publisher` |
| **Skill name** | `report-publisher` |
| **Slash command** | `/report-publisher:report-publisher` |
| **Triggers on** | "publish a report", "host this generated report", "make this report private", "version this report", "clean old report versions" |
| **Production portal** | `https://reports.resal.dev` |
| **Production auth** | `https://auth.resal.dev` |
| **Admin console** | `https://reports.resal.dev/admin/` |
| **Server path** | `/opt/report-portal` |

## What It Does

The Report Publisher skill guides Claude through publishing generated reports to the Report Portal. It supports:

- Public reports with no authentication.
- Team reports protected by Authelia login and per-report user or group grants.
- PIN reports protected by a per-report Basic Auth PIN/password.
- Markdown reports, single HTML reports, interactive HTML folders, PDFs, and static file folders.
- Replace mode or versioned publishing with `latest` updates.
- Categories, tags, retained version counts, and cleanup of older versions.
- Local publishing on the VPS and remote publishing over SSH/SCP.
- Admin follow-up for users, groups, password resets, and report grants.

## Bundled Files

The marketplace plugin includes the complete skill definition plus operational resources:

```text
plugins/report-publisher/
+-- .claude-plugin/plugin.json
+-- README.md
+-- skills/report-publisher-skill/
    +-- SKILL.md
    +-- README.md
    +-- scripts/
    |   +-- backup.sh / backup.ps1
    |   +-- common.sh
    |   +-- publish-report.sh
    |   +-- publish-report.ps1
    |   +-- remote-publish-report.sh
    |   +-- remote-publish-report.ps1
    |   +-- clean-versions.sh
    |   +-- clean-versions.ps1
    |   +-- health.sh
    |   +-- health.ps1
    |   +-- rebuild-index.sh
    |   +-- rebuild-index.ps1
    |   +-- reload-caddy.sh
    |   +-- reload-caddy.ps1
    |   +-- restore.sh / restore.ps1
    |   +-- setup-linux.sh / setup-local-linux.sh / setup-windows.ps1
    |   +-- start.sh / start.ps1 / start-local.sh / start-local.ps1
    |   +-- stop.sh / stop.ps1 / stop-local.sh / stop-local.ps1
    +-- templates/
        +-- AGENTS.md
        +-- CLAUDE.md
        +-- copilot-instructions.md
```

When publishing against production, prefer the live scripts in `/opt/report-portal/scripts`. The bundled scripts are reference copies and can be copied into a Report Portal package checkout if the local checkout is missing them.

## Prerequisites

- Claude Code with the Resal marketplace configured.
- Access to the generated report file or folder.
- For VPS-local publishing: shell access to `/opt/report-portal` and Docker Compose.
- For remote publishing: SSH access to the VPS plus `ssh`, `scp`, and `tar`.
- For Windows local testing: Docker Desktop and PowerShell.
- For Team reports: known Authelia usernames or group names, or access to the admin console to grant access later.

## How to Use

### Install the Plugin

Run this inside Claude Code:

```text
/plugin marketplace add ResalApps/resal-marketplace
/plugin install report-publisher@resal
/reload-plugins
```

### Trigger the Skill

Use natural language:

> "Publish `./generated/source-code-report` to reports.resal.dev as a team report under `engineering/source-code-review` and keep 5 versions."

> "Publish this HTML report as a PIN-protected report and version it."

Or run the slash command:

```text
/report-publisher:report-publisher
```

### Information You Will Need

| # | Input | Description | Example |
|---|-------|-------------|---------|
| 1 | Source path | Local report file or folder | `./generated/source-code-report` |
| 2 | Visibility | `public`, `team`, or `pin` | `team` |
| 3 | Relative URL | Path under the visibility route | `engineering/source-code-review` |
| 4 | Title | Display title | `Source Code Review` |
| 5 | Strategy | `replace` or `versioned` | `versioned` |
| 6 | Version | Explicit version or `auto` | `auto` |
| 7 | Category | Report category | `Engineering` |
| 8 | Tags | Comma-separated tags | `source,review,ai` |
| 9 | Access grants | Team users or groups | `admins,engineering` |
| 10 | Cleanup | How many versions to retain | `5` |
| 11 | PIN | PIN/password for `pin` reports | Provided privately |

## Workflow

### Phase 1: Gather Report Details

Claude asks for any missing source path, visibility mode, relative URL, versioning strategy, PIN, category, tags, team grants, and cleanup preference. It should not publish sensitive reports as public unless the user explicitly confirms.

### Phase 2: Choose Publish Command

Claude chooses the command based on where it is running:

- On the VPS: use `/opt/report-portal/scripts/publish-report.sh`.
- On Linux/macOS workstation: use `remote-publish-report.sh`.
- On Windows with Docker Desktop: use `publish-report.ps1` with `-Local`.
- On Windows publishing remotely: use `remote-publish-report.ps1`.

### Phase 3: Publish

Claude runs the selected command with the requested visibility, URL, title, versioning, category, tags, grants, PIN, and cleanup options.

### Phase 4: Verify and Troubleshoot

Claude returns the final URL and, if needed, runs health checks, rebuilds the index, reloads Caddy, or reminds the user to assign grants in the admin console.

## Publishing Examples

Public report on the VPS:

```bash
cd /opt/report-portal
./scripts/publish-report.sh \
  --source ./generated/source-code-report \
  --visibility public \
  --url engineering/source-code-review \
  --title "Source Code Review" \
  --strategy versioned \
  --version auto \
  --category "Engineering" \
  --tags "source,review,ai"
```

Team report with grants:

```bash
./scripts/publish-report.sh \
  --source ./generated/source-code-report \
  --visibility team \
  --url engineering/source-code-review \
  --title "Source Code Review" \
  --strategy versioned \
  --version auto \
  --access-groups "admins,engineering" \
  --category "Engineering" \
  --tags "source,review,ai" \
  --keep 5
```

PIN report:

```bash
./scripts/publish-report.sh \
  --source ./generated/source-code-report \
  --visibility pin \
  --url engineering/source-code-review \
  --title "Source Code Review" \
  --strategy versioned \
  --version auto \
  --pin "PIN_VALUE" \
  --category "Engineering" \
  --tags "pin,shared"
```

Remote publish from a workstation:

```bash
./scripts/remote-publish-report.sh \
  --server SERVER_HOST_OR_IP \
  --user SSH_USER \
  --remote-path /opt/report-portal \
  --source ./generated/source-code-report \
  --visibility team \
  --url engineering/source-code-review \
  --title "Source Code Review" \
  --strategy versioned \
  --version auto
```

## Security Defaults

- Use `team` visibility for confidential engineering, business, finance, HR, or client reports.
- Do not print the plaintext PIN in the final response unless the user explicitly asks.
- For PIN reports, remind users that the Basic Auth username is `reportuser`.
- For Team reports, login alone is not enough. Publish with `--access-users` or `--access-groups`, or grant access later from `/admin/`.
- Do not delete old versions unless the user requested cleanup or replace mode.

## Example Session

```text
User: Publish ./generated/source-code-report as a team report for engineering, version it, and keep 5 versions.

Claude: I will use the report-publisher skill. I need the relative URL and the users or groups that should have access.

User: Use engineering/source-code-review and grant admins,engineering.

Claude: Published successfully.

URL: https://reports.resal.dev/team/engineering/source-code-review/latest/
Visibility: team email/password
Strategy: versioned
Version: auto-generated
Cleanup: kept latest 5 versions
Access: groups admins,engineering
```
