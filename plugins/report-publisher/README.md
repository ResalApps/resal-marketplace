# Report Publisher Plugin

Publish generated reports to the Resal Report Portal.

## Install

```text
/plugin marketplace add ResalApps/resal-marketplace
/plugin install report-publisher@resal
```

## Use

```text
/report-publisher:report-publisher
```

Natural language also works:

```text
Publish ./generated/source-code-report to reports.resal.dev as a team report under engineering/source-code-review.
```

Full documentation: [docs/report-publisher.md](../../docs/report-publisher.md).

## MCP Publishing Setup

Remote publishing uses the Report Portal MCP publisher exposed at:

```text
https://reports.resal.dev/mcp
```

On the deployed Report Portal host, configure a long random API key in `/opt/report-portal/.env`:

```env
MCP_PUBLISH_API_KEY=replace-with-a-long-random-secret
```

Then start or restart the MCP publishing service and Caddy:

```bash
cd /opt/report-portal
docker compose up -d mcp-publisher caddy
```

Verify the endpoint before handing it to agents:

```bash
set -a
. ./.env
set +a
curl -fsS \
  -H "Authorization: Bearer $MCP_PUBLISH_API_KEY" \
  https://reports.resal.dev/mcp/healthz
```

Workstation clients should run the MCP-backed `remote-publish-report` wrapper from a full Report Portal package checkout and pass `--server-url https://reports.resal.dev`; the wrapper uploads to `/mcp/uploads` and publishes through `/mcp/publish`. The wrappers allow only `https://reports.resal.dev` and `https://reports.abushanab.net` by default; use `REPORT_PUBLISHER_ALLOW_CUSTOM_SERVER=1` only for an approved diagnostic against a named host.

## Agent Setup

Use the bundled templates for each assistant surface:

```text
Claude:  skills/report-publisher-skill/SKILL.md
Codex:   skills/report-publisher-skill/templates/AGENTS.md
Copilot: skills/report-publisher-skill/templates/copilot-instructions.md
```

Each surface should confirm the same MCP setup before remote publishing:

```text
MCP_PUBLISH_API_KEY is configured.
https://reports.resal.dev/mcp/healthz returns status ok.
Remote publish commands use --server-url / -ServerUrl and the MCP-backed wrappers.
Do not send report contents or MCP traffic to unapproved hosts.
```
