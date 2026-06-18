# Report Publisher

Publish generated reports to the self-hosted Resal Report Portal.

## Table of Contents

- [Overview](#overview)
- [What It Does](#what-it-does)
- [Bundled Files](#bundled-files)
- [Prerequisites](#prerequisites)
- [MCP Server Setup](#mcp-server-setup)
- [Agent Setup: Claude, Codex, and Copilot](#agent-setup-claude-codex-and-copilot)
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
- Local publishing on the VPS and remote publishing through the MCP publisher.
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

When publishing against production, prefer the live scripts in `/opt/report-portal/scripts`. Remote publishing should be run from a full Report Portal package checkout so Docker Compose can start the `publisher` tooling container. The bundled scripts are reference copies and can be copied into a Report Portal package checkout if the local checkout is missing them.

## Prerequisites

- Claude Code with the Resal marketplace configured.
- Access to the generated report file or folder.
- For VPS-local publishing: shell access to `/opt/report-portal` and Docker Compose.
- For remote publishing: network access to `https://reports.resal.dev/mcp`, Docker Compose, a full Report Portal package checkout, and `MCP_PUBLISH_API_KEY`.
- For Windows local testing: Docker Desktop and PowerShell.
- For Team reports: known Authelia usernames or group names, or access to the admin console to grant access later.

## MCP Server Setup

Remote publishing uses an always-on MCP publisher service in the Report Portal stack. The public surface is:

```text
https://reports.resal.dev/mcp
```

It exposes:

| Endpoint | Purpose |
|---|---|
| `/mcp/healthz` | Authenticated readiness check. |
| `/mcp/uploads` | Authenticated archive upload and staging. |
| `/mcp/publish` | Authenticated publish call using the staged upload. |

### 1. Configure the server key

On the Report Portal host:

```bash
cd /opt/report-portal
```

Add a long random secret to `.env`:

```env
MCP_PUBLISH_API_KEY=replace-with-a-long-random-secret
```

Optional settings can stay at their defaults:

```env
MCP_PUBLISH_STAGE_ROOT=/data/mcp-staging
MCP_PUBLISH_STAGE_TTL_SECONDS=3600
MCP_PUBLISH_MAX_UPLOAD_BYTES=104857600
MCP_PUBLISH_HOST=0.0.0.0
MCP_PUBLISH_PORT=8090
```

Keep this key outside source control. To rotate it, update `.env`, restart `mcp-publisher`, and update any publishing workstation that stores the old key.

### 2. Start the MCP service

Production:

```bash
docker compose -f docker-compose.yml up -d mcp-publisher caddy
```

Local validation:

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d mcp-publisher caddy
```

The current Report Portal package includes the required Caddy route for `/mcp*` to `mcp-publisher:8090`.

### 3. Verify health

Unix-like shell:

```bash
set -a
. ./.env
set +a
curl -fsS \
  -H "Authorization: Bearer $MCP_PUBLISH_API_KEY" \
  https://reports.resal.dev/mcp/healthz
```

PowerShell:

```powershell
Invoke-RestMethod `
  -Uri "https://reports.resal.dev/mcp/healthz" `
  -Headers @{ Authorization = "Bearer $env:MCP_PUBLISH_API_KEY" }
```

Expected response:

```json
{
  "status": "ok",
  "service": "mcp-publisher"
}
```

### 4. Configure publishing clients

On the workstation:

```bash
export MCP_PUBLISH_API_KEY="same-secret-as-the-server"
```

PowerShell:

```powershell
$env:MCP_PUBLISH_API_KEY = "same-secret-as-the-server"
```

Run remote publishes from a full Report Portal package checkout:

```bash
./scripts/remote-publish-report.sh \
  --server-url https://reports.resal.dev \
  --source ./generated/source-code-report \
  --visibility team \
  --url engineering/source-code-review \
  --title "Source Code Review" \
  --strategy versioned \
  --version auto
```

The wrapper archives the report locally, uploads it to `/mcp/uploads`, calls `/mcp/publish`, and forwards the same metadata, access grants, PIN, and retention options supported by local publishing.

Remote wrapper hosts are allowlisted by default: `https://reports.resal.dev` for production and
`https://reports.abushanab.net` for the local/test stack. For an approved one-off diagnostic against
another host, set `REPORT_PUBLISHER_ALLOW_CUSTOM_SERVER=1` and state the exact target URL before
running the command. Do not send report contents, upload tokens, PINs, or bearer headers to
unapproved hosts.

### 5. Troubleshooting

| Symptom | Check |
|---|---|
| `401 unauthorized` | Client key does not match `MCP_PUBLISH_API_KEY`. |
| `404` on `/mcp/healthz` | Caddy is missing the `/mcp*` route or the wrong domain is being used. |
| `502` from Caddy | `mcp-publisher` is not running or is unhealthy. |
| Upload rejected | Check `MCP_PUBLISH_MAX_UPLOAD_BYTES` and whether the archive is valid. |
| Publish fails after upload | Read the structured `/mcp/publish` error; report mutations still go through `tools/reportctl.py`. |

## Agent Setup: Claude, Codex, and Copilot

All three agent surfaces should share the same MCP assumptions:

```text
Reports endpoint: https://reports.resal.dev
MCP endpoint: https://reports.resal.dev/mcp
Required key: MCP_PUBLISH_API_KEY
Health check: GET /mcp/healthz with Authorization: Bearer <key>
Remote scripts: ./scripts/remote-publish-report.sh or ./scripts/remote-publish-report.ps1
Default strategy: versioned
Default version: auto
```

### Claude / Claude Code

Preferred install:

```text
/plugin marketplace add ResalApps/resal-marketplace
/plugin install report-publisher@resal
/reload-plugins
```

Manual install:

```text
Copy plugins/report-publisher/skills/report-publisher-skill/SKILL.md
to .claude/skills/report-publisher/SKILL.md or project instructions.
```

Claude should use the skill when the user asks to publish, protect, version, clean, or troubleshoot a report. Before remote publishing, Claude should verify `MCP_PUBLISH_API_KEY`, `/mcp/healthz`, and the `/mcp*` Caddy route.

### Codex

Copy the Codex template into the target repository:

```text
plugins/report-publisher/skills/report-publisher-skill/templates/AGENTS.md
```

Suggested target:

```text
AGENTS.md
```

Codex should read the report publisher skill before acting, then use the MCP-backed wrappers from a full Report Portal package checkout. It should not use server-copy remote publishing paths.

### GitHub Copilot

Copy or merge the Copilot template:

```text
plugins/report-publisher/skills/report-publisher-skill/templates/copilot-instructions.md
```

Suggested target:

```text
.github/copilot-instructions.md
```

Copilot should be instructed to confirm the MCP key, service health, and route before suggesting remote publish commands. It should suggest `--server-url` / `-ServerUrl` with `MCP_PUBLISH_API_KEY`.

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
- On Linux/macOS workstation: use `remote-publish-report.sh` with an approved `--server-url` and `MCP_PUBLISH_API_KEY`.
- On Windows with Docker Desktop: use `publish-report.ps1` with `-Local`.
- On Windows publishing remotely: use `remote-publish-report.ps1` with an approved `-ServerUrl` and `MCP_PUBLISH_API_KEY`.

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
  --server-url https://reports.resal.dev \
  --api-key "$MCP_PUBLISH_API_KEY" \
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
