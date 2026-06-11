# Installing the Report Publisher Skill

## Resal Marketplace

Install the plugin from the Resal Claude Code Marketplace:

```text
/plugin marketplace add ResalApps/resal-marketplace
/plugin install report-publisher@resal
```

Reload plugins if Claude Code is already running:

```text
/reload-plugins
```

Manual trigger:

```text
/report-publisher:report-publisher
```

## Claude

Copy `SKILL.md` into a Claude project instruction, Claude Code skill, or the relevant workspace instruction file.

Suggested location for Claude Code-style usage:

```text
.claude/skills/report-publisher/SKILL.md
```

For Claude Code, also install the marketplace plugin when possible:

```text
/plugin marketplace add ResalApps/resal-marketplace
/plugin install report-publisher@resal
/reload-plugins
```

Claude should read `SKILL.md` before publishing and verify the MCP server first:

```text
MCP_PUBLISH_API_KEY is configured on the Report Portal host.
https://reports.resal.dev/mcp/healthz returns status ok with the bearer key.
Remote publishing uses ./scripts/remote-publish-report.sh or .ps1 with --server-url / -ServerUrl.
```

## Codex

Copy the content of `SKILL.md` into your Codex task instructions or repository agent guidance.

Suggested location:

```text
AGENTS.md
```

Add a section titled:

```text
Report Publisher Skill
```

For repository-level Codex usage, copy `templates/AGENTS.md` into the target repository's `AGENTS.md`, then add or keep a pointer to this skill:

```text
Use skills/report-publisher-skill/SKILL.md for report publishing.
Remote publishing requires MCP_PUBLISH_API_KEY and https://reports.resal.dev/mcp/healthz.
Use ./scripts/remote-publish-report.sh or .ps1 from a full Report Portal package checkout.
```

## GitHub Copilot

Copy the relevant parts of `SKILL.md` into repository instructions.

Suggested location:

```text
.github/copilot-instructions.md
```

For Copilot, copy `templates/copilot-instructions.md` into `.github/copilot-instructions.md` or merge it into the existing file. The instruction must tell Copilot to:

```text
Confirm MCP_PUBLISH_API_KEY is configured.
Confirm mcp-publisher is running.
Confirm /mcp/healthz returns status ok.
Use the MCP-backed remote-publish-report wrappers, not server shell copy steps.
```

## Required Tooling for Agents

The agent needs shell access to either:

1. The VPS where `/opt/report-portal` is installed, or
2. A local machine with Docker access, a full Report Portal package checkout, and network access to the deployed MCP publisher endpoint.

For remote publishing, the agent must be able to run:

```text
docker compose
./scripts/remote-publish-report.sh
./scripts/remote-publish-report.ps1
```

The deployed stack must expose `/mcp`, `/mcp/uploads`, and `/mcp/publish`, and define `MCP_PUBLISH_API_KEY`. The remote wrappers authenticate with that single bearer API key and do not require server shell access.

## MCP Server Setup

Remote publishing is available only after the Report Portal deployment is running the `mcp-publisher` service behind Caddy.

### 1. Configure the API key

On the Report Portal host:

```bash
cd /opt/report-portal
```

Create a long random secret and add it to `.env`:

```env
MCP_PUBLISH_API_KEY=replace-with-a-long-random-secret
```

Optional MCP settings can stay at their defaults unless the deployment needs different staging or upload limits:

```env
MCP_PUBLISH_STAGE_ROOT=/data/mcp-staging
MCP_PUBLISH_STAGE_TTL_SECONDS=3600
MCP_PUBLISH_MAX_UPLOAD_BYTES=104857600
MCP_PUBLISH_HOST=0.0.0.0
MCP_PUBLISH_PORT=8090
```

Keep the API key outside source control. Rotate it by changing `.env` and restarting `mcp-publisher`.

### 2. Start the service

Production:

```bash
docker compose -f docker-compose.yml up -d mcp-publisher caddy
```

Local validation:

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up -d mcp-publisher caddy
```

Caddy must route `/mcp*` to `mcp-publisher:8090`; current Report Portal packages include this route in `caddy/Caddyfile` and `caddy/Caddyfile.local`.

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

### 4. Configure publisher clients

On the workstation that will publish reports:

```bash
export MCP_PUBLISH_API_KEY="same-secret-as-the-server"
```

PowerShell:

```powershell
$env:MCP_PUBLISH_API_KEY = "same-secret-as-the-server"
```

Run remote publishes from a full Report Portal package checkout so Docker Compose can start the `publisher` tooling container:

```bash
./scripts/remote-publish-report.sh \
  --server-url https://reports.resal.dev \
  --source ./generated-report \
  --visibility team \
  --url engineering/source-code-review \
  --title "Source Code Review" \
  --strategy versioned \
  --version auto
```

The wrapper archives the source locally, uploads it to `/mcp/uploads`, calls `/mcp/publish`, and forwards the same publishing options used by local `reportctl.py` publishes.

### 5. Troubleshooting

| Symptom | Check |
|---|---|
| `401 unauthorized` | The client key must match `MCP_PUBLISH_API_KEY` in the deployment. |
| `404` on `/mcp/healthz` | Caddy is missing the `/mcp*` route or the wrong domain is being used. |
| `502` from Caddy | `mcp-publisher` is not running or is unhealthy. |
| Upload rejected | Check `MCP_PUBLISH_MAX_UPLOAD_BYTES` and confirm the report archive is valid. |
| Publish fails after upload | Read the structured error from `/mcp/publish`; publish mutations still go through `tools/reportctl.py`. |

For local publishing on the VPS, the agent must be able to run:

```text
docker compose
./scripts/publish-report.sh
```

On Windows with Docker Desktop, the agent can use the PowerShell scripts:

```text
docker compose
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/publish-report.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/start-local.ps1
```

## Bundled Marketplace Resources

The marketplace plugin bundles the skill definition, agent instruction templates,
and the report portal helper scripts:

```text
skills/report-publisher-skill/
+-- SKILL.md
+-- README.md
+-- scripts/
|   +-- publish-report.sh
|   +-- publish-report.ps1
|   +-- remote-publish-report.sh
|   +-- remote-publish-report.ps1
|   +-- clean-versions.sh
|   +-- clean-versions.ps1
|   +-- common.sh
|   +-- health.sh
|   +-- health.ps1
|   +-- rebuild-index.sh
|   +-- rebuild-index.ps1
|   +-- reload-caddy.sh
|   +-- reload-caddy.ps1
|   +-- backup.sh / backup.ps1
|   +-- restore.sh / restore.ps1
|   +-- setup-linux.sh / setup-local-linux.sh / setup-windows.ps1
|   +-- start.sh / start.ps1 / start-local.sh / start-local.ps1
|   +-- stop.sh / stop.ps1 / stop-local.sh / stop-local.ps1
+-- templates/
    +-- AGENTS.md
    +-- CLAUDE.md
    +-- copilot-instructions.md
```

## Current Portal Behavior

- `https://reports.resal.dev/` is the public landing page; users do not need `/public/` to browse public or PIN-protected reports.
- The landing page, generated index/category pages, generated Markdown pages, fallback directory pages, and admin console share the Resal-branded theme (resal.me logo, violet palette, sidebar navigation) with a visible `Administration` link and clickable retained-version links.
- `https://reports.resal.dev/admin/` is the admin console for portal users, passwords, groups, report grants, user deletion, and password resets.
- Admin user/group and report-access forms use multi-select dropdowns; report rows have an `Edit Access` modal.
- Team reports require Authelia login plus a matching portal user or group grant, and stay hidden from users without access.
- PIN reports use username `reportuser` and the per-report PIN/password set during publish.
- Publishing supports `Category`, `Tags`, `AccessUsers`, `AccessGroups`, and per-report retained-version counts.

Local test equivalents:

```text
https://reports.abushanab.test/
https://reports.abushanab.test/admin/
https://auth.abushanab.test/
```
