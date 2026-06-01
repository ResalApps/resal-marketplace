# GitHub Copilot Instructions — Report Publisher

When asked to publish generated reports, follow the Report Publisher Skill workflow.

Use local scripts in `/opt/report-portal/scripts` when operating on the VPS. From a workstation, use the MCP-backed remote wrappers `./scripts/remote-publish-report.sh` or `./scripts/remote-publish-report.ps1`; they upload to `/mcp/uploads`, publish through `/mcp/publish`, and authenticate with `MCP_PUBLISH_API_KEY`.

Before remote publishing, confirm the deployed Report Portal has `MCP_PUBLISH_API_KEY` set, `mcp-publisher` running, and `/mcp/healthz` returning `status: ok`. Prefer `versioned` with `auto` versions unless the user asks to replace. Do not publish sensitive reports publicly unless the user explicitly confirms.
