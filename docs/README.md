# Resal Marketplace - Documentation

Documentation for all plugins available in the Resal Claude Code Marketplace.

## Table of Contents

### Getting Started

- [Installation](#installation)
- [Usage](#usage)
- [Contributing](contributing.md)

### Plugins

| # | Plugin | Description | Skills | Docs |
|---|--------|-------------|--------|------|
| 1 | **add-app-deployment** | Add deployment pipelines for new apps to the Resal GitOps infrastructure | 1 skill | [View docs](add-app-deployment.md) |
| 2 | **resal-pm-plugin** | AI-first product management: idea evaluation, PRDs, competitive analysis, stakeholder updates, research, data analysis | 8 skills, 1 command | [View docs](resal-pm-plugin.md) |

---

## Installation

### Step 1: Add the marketplace

Run this inside Claude Code:

```
/plugin marketplace add ResalApps/resal-marketplace
```

### Step 2: Install plugins

```
/plugin install add-app-deployment@resal
/plugin install resal-pm-plugin@resal
```

### Step 3: Verify

Run `/reload-plugins` then check the plugins appear in your skill list.

## Usage

Plugins can be triggered in two ways:

**Automatic** - Claude detects when a plugin is relevant based on your request. Examples:

| Say this... | Plugin activated |
|-------------|-----------------|
| "Deploy a new service to dev and staging" | add-app-deployment |
| "I have an idea for a new feature" | resal-pm-plugin (evaluate-idea) |
| "Write a PRD for the subscription system" | resal-pm-plugin (write-spec) |
| "What are our competitors doing?" | resal-pm-plugin (competitive-brief) |
| "Prepare a status update for leadership" | resal-pm-plugin (stakeholder-update) |
| "Analyze our conversion metrics" | resal-pm-plugin (data-analysis) |

**Manual** - Use slash commands directly:

| Command | Description |
|---------|-------------|
| `/add-app-deployment:add-app-deployment` | Deploy a new app to dev/staging |
| `/resal-pm-plugin:evaluate-idea` | Evaluate a product idea |
| `/resal-pm-plugin:write-spec` | Write a PRD |
| `/resal-pm-plugin:prd-to-spec` | Decompose PRD into technical specs |
| `/resal-pm-plugin:solution-analyst` | Analyze technical solutions |
| `/resal-pm-plugin:competitive-brief` | Competitive analysis |
| `/resal-pm-plugin:stakeholder-update` | Write status updates |
| `/resal-pm-plugin:research-discovery` | Research and discovery |
| `/resal-pm-plugin:data-analysis` | Analyze metrics and data |
| `/resal-pm-plugin:philosophy` | Show PM philosophy |

## Contributing

To add a new plugin to the marketplace, see the [Contributing Guide](contributing.md).
