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

## GitHub Copilot

Copy the relevant parts of `SKILL.md` into repository instructions.

Suggested location:

```text
.github/copilot-instructions.md
```

## Required Tooling for Agents

The agent needs shell access to either:

1. The VPS where `/opt/report-portal` is installed, or
2. A local machine with SSH access to the VPS and this package available.

For remote publishing, the agent must be able to run:

```text
ssh
scp
tar
```

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
- The landing page, generated index/category pages, generated Markdown pages, fallback directory pages, and admin console share the report-card theme with a visible `Admin` link and clickable retained-version links.
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
