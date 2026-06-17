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
| 2 | **report-publisher** | Publish generated reports to the Resal Report Portal with public, team login, or PIN protection | 1 skill | [View docs](report-publisher.md) |
| 3 | **devtools** | Developer productivity tools: PR review feedback, multi-stack coding-standards review, QA How-To-Test manuals, and detailed PR/changelog + feature-details generation | 4 skills | [View docs](devtools.md) |
| 4 | **resal-pm-plugin** | AI-first product management: idea evaluation, PRDs, competitive analysis, stakeholder updates, research, data analysis | 8 skills, 1 command | [View docs](resal-pm-plugin.md) |

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
/plugin install report-publisher@resal
/plugin install devtools@resal
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
| "Publish this generated report to reports.resal.dev as a PIN report" | report-publisher |
| "Address the review comments on ResalApps/example#123" | devtools (pr-review) |
| "Generate a How-To-Test guide for this feature" | devtools (how-to-test) |
| "Generate a detailed PR / write the PR description for this feature" | devtools (speckit-pr-generate) |
| "I have an idea for a new feature" | resal-pm-plugin (evaluate-idea) |
| "Write a PRD for the subscription system" | resal-pm-plugin (write-spec) |
| "What are our competitors doing?" | resal-pm-plugin (competitive-brief) |
| "Prepare a status update for leadership" | resal-pm-plugin (stakeholder-update) |
| "Analyze our conversion metrics" | resal-pm-plugin (data-analysis) |

**Manual** - Use slash commands directly:

| Command | Description |
|---------|-------------|
| `/add-app-deployment:add-app-deployment` | Deploy a new app to dev/staging |
| `/report-publisher:report-publisher` | Publish a generated report |
| `/devtools:pr-review` | Process PR review feedback |
| `/devtools:how-to-test` | Generate a QA How-To-Test manual for a feature |
| `/devtools:resal-standards-review` | Audit a project against Resal standards |
| `/devtools:speckit-pr-generate` | Generate CHANGELOG + feature-details doc and fill the PR description |
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
