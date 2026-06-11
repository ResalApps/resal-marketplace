# Claude Instructions — Report Publisher

Use `skills/report-publisher-skill/SKILL.md` when the user asks to publish, update, protect, replace, version, or clean generated reports on the Report Portal.

Always ask for missing source path, visibility mode, relative URL, versioning strategy, PIN if needed, metadata/access grants, and cleanup preference.

For remote publishing, first confirm the MCP server is configured: `MCP_PUBLISH_API_KEY` set on the deployed Report Portal, `/mcp/healthz` healthy, and Caddy routing `/mcp*` to `mcp-publisher`. Use `./scripts/remote-publish-report.sh` or `./scripts/remote-publish-report.ps1`; they upload to `/mcp/uploads`, publish through `/mcp/publish`, and authenticate with `MCP_PUBLISH_API_KEY`.
