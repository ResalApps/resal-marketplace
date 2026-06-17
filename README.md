# Resal Marketplace

A collection of Claude Code plugins for the Resal engineering and product teams. Each plugin encodes repeatable workflows and domain knowledge so any team member can execute complex tasks consistently.

## Available Plugins

| Plugin                                           | Description                                                                                                                                   | Skills              | Source                                                  |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ------------------------------------------------------- |
| [add-app-deployment](docs/add-app-deployment.md) | Add deployment pipelines for new apps (ECR, Helm, ArgoCD, GitHub Actions)                                                                     | 1 skill             | Local                                                   |
| [report-publisher](docs/report-publisher.md)     | Publish generated reports to the Resal Report Portal with public, team login, or PIN protection                                               | 1 skill             | Local                                                   |
| [devtools](docs/devtools.md)                     | Developer productivity tools: PR review feedback, multi-stack coding-standards review, QA How-To-Test manuals, and detailed PR/changelog + feature-details generation | 4 skills            | Local                                                   |
| [resal-pm-plugin](docs/resal-pm-plugin.md)       | AI-first product management: idea evaluation, PRDs, competitive analysis, stakeholder updates, research, data analysis                        | 8 skills, 1 command | [AI_Workflow](https://github.com/ResalApps/AI_Workflow) |

## Quick Start

### 1. Add the marketplace

```
/plugin marketplace add ResalApps/resal-marketplace
```

### 2. Install plugins

```
/plugin install add-app-deployment@resal
/plugin install report-publisher@resal
/plugin install devtools@resal
/plugin install resal-pm-plugin@resal
```

### 3. Use them

Plugins trigger automatically based on context, or use slash commands:

```
/add-app-deployment:add-app-deployment    # Deploy a new app
/report-publisher:report-publisher        # Publish a generated report
/devtools:pr-review                       # Process PR review feedback
/devtools:how-to-test                     # Generate a QA How-To-Test manual for a feature
/devtools:speckit-pr-generate             # Generate CHANGELOG + feature-details, fill the PR description
/resal-pm-plugin:evaluate-idea            # Evaluate a product idea
/resal-pm-plugin:write-spec               # Write a PRD
/resal-pm-plugin:competitive-brief        # Competitive analysis
```

## Spec Kit Extensions

Besides Claude Code plugins, this repo also hosts **Spec Kit extensions** under
[`extensions/`](extensions/). These hook into the Spec Kit (`specify`) workflow rather than the
Claude Code `/plugin` system. Full guide: [`extensions/README.md`](extensions/README.md).

| Extension             | ID   | Command                | What it does                                                                                                                                                      |
| --------------------- | ---- | ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Detailed PR Generator | `pr` | `/speckit-pr-generate` | Generates a **CHANGELOG** + plain-English **feature-details** doc, then creates/updates the PR description under "What have been developed and how to review it". |

### Install (requires the `specify` CLI and a `.specify/` project)

**By name, via the catalog** — add the catalog once, then install:

```bash
specify extension catalog add --name resal --install-allowed https://raw.githubusercontent.com/ResalApps/resal-marketplace/master/extensions/catalog.json

specify extension add pr
```

> By-name (and `--from`) installs need a published release ZIP. Until one is cut, use the local dev
> install below.

**Local dev install from a clone** (works today, no release needed):

```bash
git clone https://github.com/ResalApps/resal-marketplace
# from inside your Spec Kit project:
specify extension add --dev /path/to/resal-marketplace/extensions/pr
```

> ⚠️ Point `--dev` at the **external clone** path — never at a path inside your project's own
> `.specify/extensions/` (the CLI deletes the destination before copying, which would wipe the source).

### Use the `pr` extension

After install the command is available as `/speckit-pr-generate`:

```bash
/speckit-pr-generate                 # write docs + create/update the PR description
/speckit-pr-generate --no-pr         # generate/refresh docs only
/speckit-pr-generate --create-pr     # also create the PR if none exists
/speckit-pr-generate --feature specs/006-finance-settlement-ledger   # override feature detection
```

It also registers an **optional** `after_implement` hook, so Spec Kit can prompt to run it
automatically once implementation finishes. It writes `docs/<feature>/CHANGELOG.md` and
`docs/<feature>/<Feature>-Explained.md`, then injects the feature-details into the PR body under a
marker-delimited section — **idempotent**, so re-running refreshes rather than duplicates. The same
capability is available as the `/devtools:speckit-pr-generate` plugin skill for use outside Spec Kit.

## Documentation

Full documentation for each plugin is in the [docs/](docs/) folder:

- [Docs Index](docs/README.md) - TOC and installation guide
- [add-app-deployment](docs/add-app-deployment.md) - Deployment pipeline setup
- [report-publisher](docs/report-publisher.md) - Report publishing workflow
- [devtools](docs/devtools.md) - Developer productivity tools
- [resal-pm-plugin](docs/resal-pm-plugin.md) - Product management skills
- [Spec Kit extensions](extensions/) - `specify` CLI workflow extensions (e.g. the `pr` Detailed PR Generator)
- [Contributing](docs/contributing.md) - How to add new plugins

## Development

### Loading a plugin locally for testing

```bash
claude --plugin-dir ./plugins/add-app-deployment
```

Use `/reload-plugins` inside Claude Code to pick up changes without restarting.

## Repository Structure

```
resal-marketplace/
|-- .claude-plugin/
|   +-- marketplace.json             # Plugin registry
|-- README.md
|-- docs/
|   |-- README.md                    # Docs index with TOC
|   |-- add-app-deployment.md        # Deployment plugin docs
|   |-- report-publisher.md          # Report publisher docs
|   |-- devtools.md                  # Developer tools docs
|   |-- resal-pm-plugin.md           # PM plugin docs
|   +-- contributing.md              # How to add plugins
+-- plugins/
    |-- add-app-deployment/          # Local plugin
    |   |-- .claude-plugin/
    |   |   +-- plugin.json
    |   +-- skills/
    |       +-- add-app-deployment/
    |           |-- SKILL.md
    |           +-- references/
    +-- report-publisher/            # Local plugin
        |-- .claude-plugin/
        |   +-- plugin.json
        |-- README.md
        +-- skills/
            +-- report-publisher-skill/
                |-- SKILL.md
                |-- README.md
                |-- scripts/
                +-- templates/
    +-- devtools/                    # Local plugin
        |-- .claude-plugin/
        |   +-- plugin.json
        |-- README.md
        +-- skills/
            |-- pr-review/
            |   +-- SKILL.md
            |-- how-to-test/
            |   +-- SKILL.md
            |-- resal-standards-review/
            |   +-- SKILL.md
            +-- speckit-pr-generate/
                +-- SKILL.md
|-- extensions/                      # Spec Kit (`specify`) extensions
|   |-- catalog.json                 # Extension catalog (install by name)
|   |-- README.md                    # Install + publishing guide
|   |-- scripts/package.sh           # Build a release ZIP
|   +-- pr/                          # Detailed PR Generator extension
|       |-- extension.yml
|       +-- commands/
```

> **Note:** `resal-pm-plugin` is sourced externally from [ResalApps/AI_Workflow](https://github.com/ResalApps/AI_Workflow) and not stored in this repo.
>
> **Plugins vs extensions:** [`plugins/`](plugins/) hold Claude Code plugins (skills/slash-commands); [`extensions/`](extensions/) hold Spec Kit workflow extensions installed with the `specify` CLI. The `pr` extension and the `devtools:speckit-pr-generate` skill are twins — same name, same behavior, different runtimes.
