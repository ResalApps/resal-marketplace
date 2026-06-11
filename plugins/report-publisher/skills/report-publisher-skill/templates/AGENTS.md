# Codex / Agent Instructions — Report Publisher

Use the Report Publisher Skill for generated report publishing tasks.

Portal:
- Reports: https://reports.resal.dev
- Auth: https://auth.resal.dev
- Server path: /opt/report-portal
- Remote MCP endpoint: https://reports.resal.dev/mcp

Before publishing, collect: source path, visibility, relative URL, replace/versioned strategy, optional version, optional PIN, category/tags, Team users/groups, and cleanup policy.

For remote publishing from a workstation, use the MCP-backed wrappers:
- `./scripts/remote-publish-report.sh`
- `./scripts/remote-publish-report.ps1`

The deployed server must define `MCP_PUBLISH_API_KEY` and expose `/mcp`, `/mcp/uploads`, and `/mcp/publish`. The wrappers authenticate with `MCP_PUBLISH_API_KEY` and default to `versioned` with `auto` versions.
