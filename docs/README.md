# Resal Marketplace - Documentation

Documentation for all plugins available in the Resal Claude Code Marketplace.

## Table of Contents

### Getting Started

- [Installation](#installation)
- [Usage](#usage)

### Plugins

| # | Plugin | Description | Docs |
|---|--------|-------------|------|
| 1 | **add-app-deployment** | Add deployment pipeline for new apps to the Resal GitOps infrastructure | [View docs](add-app-deployment.md) |
| 2 | **report-publisher** | Publish generated reports to the Resal Report Portal with public, team login, or PIN protection | [View docs](report-publisher.md) |
| 3 | **resal-pm-plugin** | AI-first product management: idea evaluation, PRDs, competitive analysis, stakeholder updates, research, data analysis | [View docs](resal-pm-plugin.md) |

---

## Installation

### Step 1: Add the marketplace

Run this inside Claude Code:

```
/plugin marketplace add ResalApps/resal-marketplace
```

### Step 2: Install a plugin

```
/plugin install add-app-deployment@resal
```

For report publishing:

```
/plugin install report-publisher@resal
```

### Step 3: Verify

Run `/reload-plugins` then check the plugin appears in your skill list.

## Usage

Plugins can be triggered in two ways:

**Automatic** - Claude detects when a plugin is relevant based on your request. For example, saying "deploy a new service to dev and staging" will activate the `add-app-deployment` plugin automatically.

**Manual** - Use the slash command directly:

```
/add-app-deployment:add-app-deployment
```

Report publishing command:

```
/report-publisher:report-publisher
```

## Contributing

To add a new plugin to the marketplace, see the [Contributing Guide](contributing.md).
