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

### Step 3: Verify

Run `/reload-plugins` then check the plugin appears in your skill list.

## Usage

Plugins can be triggered in two ways:

**Automatic** - Claude detects when a plugin is relevant based on your request. For example, saying "deploy a new service to dev and staging" will activate the `add-app-deployment` plugin automatically.

**Manual** - Use the slash command directly:

```
/add-app-deployment:add-app-deployment
```

## Contributing

To add a new plugin to the marketplace, see the [Contributing Guide](contributing.md).
