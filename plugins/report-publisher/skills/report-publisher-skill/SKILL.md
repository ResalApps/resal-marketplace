---
name: report-publisher
description: Use when publishing, updating, protecting, categorizing, versioning, cleaning, or troubleshooting generated reports on the self-hosted Report Portal.
---

# Report Publisher Skill

Use this skill whenever the user asks to publish, host, update, replace, version, protect, or clean a generated report on the self-hosted Report Portal.

The target portal is:

```text
Production reports URL: https://reports.resal.dev
Production auth URL:    https://auth.resal.dev
Production admin URL:   https://reports.resal.dev/admin/
Server path:            /opt/report-portal
```

For this workspace's local test stack, use:

```text
Local reports URL: https://reports.abushanab.test
Local auth URL:    https://auth.abushanab.test
Admin URL:         https://reports.abushanab.test/admin/
```

The default reports URL `/` is the public landing page. Users do not need `/public/` to browse public or PIN-protected reports, though individual public report files still live under `/public/...` and PIN reports live under `/pin/...`. Team reports stay hidden unless the signed-in user has access. The landing page, generated indexes, category pages, generated Markdown pages, fallback directory pages, and admin console share the report-card theme, include an `Admin` link, and make retained versions clickable.

## What This Skill Does

This skill helps publish generated reports to the Report Portal with one of three access modes:

1. Public — no authentication.
2. Team — protected by Authelia login plus per-report user/group grants.
3. PIN — protected by a per-report PIN/password.

It supports:

- Markdown reports
- HTML reports
- Interactive HTML folders
- PDF/static file folders
- Replacing old reports
- Retaining version history
- Cleaning older versions
- Per-report retained-version counts
- Scheduled cleanup in the portal service
- Categories and tags
- Team access grants by user or group
- Portal admin management at `/admin/`
- Publishing locally on the VPS
- Publishing remotely over SSH/SCP

## Bundled Resources

This marketplace skill includes supporting files so agents can inspect the exact
Report Portal publishing interface without hunting through the portal package:

```text
scripts/
  backup.sh
  backup.ps1
  clean-versions.sh
  clean-versions.ps1
  common.sh
  health.sh
  health.ps1
  publish-report.sh
  publish-report.ps1
  rebuild-index.sh
  rebuild-index.ps1
  reload-caddy.sh
  reload-caddy.ps1
  remote-publish-report.sh
  remote-publish-report.ps1
  restore.sh
  restore.ps1
  setup-linux.sh
  setup-local-linux.sh
  setup-windows.ps1
  start.sh
  start.ps1
  start-local.sh
  start-local.ps1
  stop.sh
  stop.ps1
  stop-local.sh
  stop-local.ps1
templates/
  AGENTS.md
  CLAUDE.md
  copilot-instructions.md
```

Prefer the live scripts in `/opt/report-portal/scripts` when publishing on the
VPS, or the checked-out Report Portal package scripts when publishing from a
workstation. Use the bundled scripts as reference copies or as files to copy
into a Report Portal package checkout when the package scripts are missing.

## Required Questions

Before publishing, ask the user for any missing information below.

### 1. Source Path

Ask:

> What is the local path to the generated report file or folder?

Examples:

```text
./report.html
./generated-report/
./site/
./docs/report.md
```

### 2. Protection Mode

Ask:

> How should this report be protected: public, team email/password, or PIN?

Map the answer:

| User answer | Visibility |
|---|---|
| public / open / no password | `public` |
| email/password / login / team / private | `team` |
| PIN / password link / simple password | `pin` |

### 3. Relative URL

Ask:

> What relative URL should be used under the visibility path?

Examples:

```text
architecture/platform-review
vendors/odoo-assessment
ai/generated-analysis
```

Resulting URLs:

```text
https://reports.resal.dev/
https://reports.resal.dev/public/architecture/platform-review/latest/
https://reports.resal.dev/team/vendors/odoo-assessment/latest/
https://reports.resal.dev/pin/ai/generated-analysis/latest/
```

### 4. Replace or Version

Ask:

> Should I overwrite the previous report, or retain it as a version and update `latest`?

Map the answer:

| User answer | Strategy |
|---|---|
| overwrite / replace / update only latest | `replace` |
| retain / keep history / version | `versioned` |

If unsure, recommend `versioned`.

### 5. Version Name

If the user chooses versioned publishing, ask:

> Do you want an explicit version name, or should I generate one automatically?

Default:

```text
auto
```

Examples:

```text
v1
v2
v2026-05-27
client-review-v3
```

### 6. PIN

If protection mode is PIN, ask:

> What PIN/password should be used for this report?

Warn gently that short numeric PINs are not appropriate for sensitive reports.

The username will be:

```text
reportuser
```

The publisher hashes the PIN locally and stores a SHA-256 digest in report metadata. Do not print the plaintext PIN unless the user explicitly asks.

### 7. Category and Tags

Ask:

> What category and tags should this report use?

Defaults:

```text
category: General
tags: none
```

Examples:

```text
category: Finance
tags: q2,board,forecast
```

### 8. Team Access

If protection mode is Team, ask:

> Which users or groups should be able to access this report?

Use Authelia usernames and group names. Access can be set at publish time with `--access-users` / `--access-groups`, or later from the admin page:

```text
https://reports.resal.dev/admin/
```

Local admin page:

```text
https://reports.abushanab.test/admin/
```

### 9. Cleanup Older Versions

Ask:

> Should older versions be cleaned? If yes, how many versions should be kept?

If the user says yes but does not provide a number, recommend:

```text
keep 5
```

If the user does not specify cleanup, use the report's saved retention count. New reports default to 5 retained versions.

## Local VPS Publishing Command

When running on the VPS inside `/opt/report-portal`, use:

```bash
./scripts/publish-report.sh \
  --source SOURCE_PATH \
  --visibility VISIBILITY \
  --url RELATIVE_URL \
  --title "REPORT_TITLE" \
  --strategy versioned \
  --version auto \
  --type auto \
  --category "General" \
  --tags "optional,tags"
```

For Team grants:

```bash
./scripts/publish-report.sh \
  --source SOURCE_PATH \
  --visibility team \
  --url RELATIVE_URL \
  --title "REPORT_TITLE" \
  --strategy versioned \
  --version auto \
  --access-users "samy,fatima" \
  --access-groups "admins,finance" \
  --category "Finance" \
  --tags "q2,board" \
  --keep 5
```

For PIN:

```bash
./scripts/publish-report.sh \
  --source SOURCE_PATH \
  --visibility pin \
  --url RELATIVE_URL \
  --title "REPORT_TITLE" \
  --strategy versioned \
  --version auto \
  --pin "PIN_VALUE" \
  --category "General" \
  --tags "pin,shared"
```

With cleanup:

```bash
./scripts/publish-report.sh \
  --source SOURCE_PATH \
  --visibility team \
  --url RELATIVE_URL \
  --title "REPORT_TITLE" \
  --strategy versioned \
  --version auto \
  --keep 5
```

## Windows Local Publishing Command

From the package folder on Windows with Docker Desktop:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/publish-report.ps1 `
  -Source SOURCE_PATH `
  -Visibility public `
  -Url RELATIVE_URL `
  -Title "REPORT_TITLE" `
  -Strategy versioned `
  -Version auto `
  -Type auto `
  -Category "General" `
  -Tags "optional,tags" `
  -Local
```

Team with grants:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/publish-report.ps1 `
  -Source SOURCE_PATH `
  -Visibility team `
  -Url RELATIVE_URL `
  -Title "REPORT_TITLE" `
  -Strategy versioned `
  -AccessUsers "samy,fatima" `
  -AccessGroups "admins,finance" `
  -Category "Finance" `
  -Tags "q2,board" `
  -Keep 5 `
  -Local
```

PIN:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/publish-report.ps1 `
  -Source SOURCE_PATH `
  -Visibility pin `
  -Url RELATIVE_URL `
  -Title "REPORT_TITLE" `
  -Strategy versioned `
  -Pin "PIN_VALUE" `
  -Category "General" `
  -Tags "pin,shared" `
  -Local
```

## Remote Publishing Command

When publishing from another machine to the VPS:

```bash
./scripts/remote-publish-report.sh \
  --server SERVER_HOST_OR_IP \
  --user SSH_USER \
  --remote-path /opt/report-portal \
  --source SOURCE_PATH \
  --visibility VISIBILITY \
  --url RELATIVE_URL \
  --title "REPORT_TITLE" \
  --strategy versioned \
  --version auto \
  --type auto \
  --category "General" \
  --tags "optional,tags"
```

For PowerShell:

```powershell
./scripts/remote-publish-report.ps1 `
  -Server SERVER_HOST_OR_IP `
  -User SSH_USER `
  -RemotePath /opt/report-portal `
  -Source SOURCE_PATH `
  -Visibility VISIBILITY `
  -Url RELATIVE_URL `
  -Title "REPORT_TITLE" `
  -Strategy versioned `
  -Version auto `
  -Type auto
```

## Admin and Access Management

Use the admin page to add portal users, set/reset passwords, assign groups, delete users, and manage report grants:

```text
https://reports.resal.dev/admin/
https://reports.abushanab.test/admin/
```

Important distinction:

- Authelia users in `authelia/users_database.yml` control login.
- Portal users/groups/grants control which Team reports a signed-in user can open.
- Admin access requires the signed-in Authelia user to be in the `admins` group.
- The admin page writes `authelia/users_database.yml` and hashes raw passwords with the bundled Authelia binary.
- User/group and report-access controls use multi-select dropdowns. Report rows expose an `Edit Access` modal for assigning users and groups.

To add a new Team user:

1. Open `/admin/`.
2. Add the username, display name, email, password, role, and groups.
3. Use the report row `Edit Access` action to assign that user or their groups to a report.
4. Use the Users table actions to reset passwords or delete users.

## Cleanup Command

```bash
./scripts/clean-versions.sh \
  --visibility VISIBILITY \
  --url RELATIVE_URL \
  --keep 5
```

PowerShell:

```powershell
./scripts/clean-versions.ps1 \
  -Visibility VISIBILITY \
  -Url RELATIVE_URL \
  -Keep 5
```

## Decision Rules

Use these defaults unless the user gives different instructions:

| Missing input | Default |
|---|---|
| Visibility | Ask; do not assume |
| Relative URL | Ask; do not invent for production |
| Strategy | Recommend `versioned` |
| Version | `auto` |
| Type | `auto` |
| Category | `General` |
| Tags | none |
| Team access | Ask for users/groups; can also be granted in `/admin/` |
| Cleanup | Use saved retention count; default for new reports is 5 |
| PIN | Ask if visibility is `pin` |
| Report title | Infer from folder/file name if not provided |

## Final Response After Publishing

After publishing, tell the user:

1. The visibility mode used.
2. The final report URL.
3. Whether it was replaced or versioned.
4. The retained version name if known.
5. Cleanup result if cleanup was performed.
6. Category/tags if supplied.
7. Team users/groups or admin-grant reminder if visibility is `team`.
8. PIN username reminder if visibility is `pin`.

Example:

```text
Published successfully.

URL: https://reports.resal.dev/team/architecture/platform-review/latest/
Visibility: team email/password
Strategy: versioned
Version: auto-generated
Cleanup: kept latest 5 versions
Access: users samy; groups admins
```

## Safety and Security Rules

- Do not publish sensitive reports as public unless the user explicitly confirms.
- Do not recommend short PINs for sensitive reports.
- Never print a PIN back to the user unless they explicitly ask to confirm it.
- Do not delete old versions unless the user requested cleanup or replace mode.
- Use `team` visibility for confidential engineering, business, financial, HR, or client reports.
- For Team reports, do not assume login alone is enough; publish with access grants or tell the user to grant access in `/admin/`.
- For PIN reports, remind the user the Basic Auth username is `reportuser`.

## Troubleshooting

If publishing succeeds but the URL does not open:

1. Run:

```bash
./scripts/health.sh
```

2. Rebuild the index:

```bash
./scripts/rebuild-index.sh
```

3. Reload Caddy:

```bash
./scripts/reload-caddy.sh
```

4. Check that the DNS records point to the VPS.

5. Check that ports 80 and 443 are open.

If Team login succeeds but the report is forbidden:

1. Confirm the report metadata includes the correct `allowed_users` or `allowed_groups`.
2. Open `/admin/` and grant the user or group to the report.
3. Confirm Authelia sends the expected username/group names.

If a PIN report does not prompt or rejects the password:

1. Republish the same URL with `--pin` / `-Pin` to rotate the PIN.
2. Confirm the report metadata has `pin_enabled: true`.
3. Use username `reportuser` with the selected PIN/password.
