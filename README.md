# Resal Marketplace

A collection of Claude Code plugins for the Resal DevOps and engineering team. Each plugin encodes repeatable workflows and domain knowledge so any team member can execute complex infrastructure tasks consistently.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [add-app-deployment](plugins/add-app-deployment/) | Add deployment pipeline for new apps (ECR, Helm, ArgoCD, GitHub Actions) |

## Installation

### Add the marketplace

```bash
claude marketplace add resal https://raw.githubusercontent.com/ResalApps/resal-marketplace/master/marketplace.json
```

### Install a plugin

```bash
# Install to user scope (available in all projects)
claude plugin install add-app-deployment@resal

# Install to project scope (shared with team via git)
claude plugin install add-app-deployment@resal --scope project
```

### Install all plugins

```bash
claude plugin install add-app-deployment@resal
```

## Usage

Once installed, plugins are available as slash commands:

```
/add-app-deployment:add-app-deployment
```

Or they trigger automatically based on context. For example, saying "deploy a new service to dev and staging" will activate the `add-app-deployment` plugin.

## Development

### Loading a plugin locally for testing

```bash
claude --plugin-dir ./plugins/add-app-deployment
```

Use `/reload-plugins` inside Claude Code to pick up changes without restarting.

### Adding a new plugin

1. Create a new directory under `plugins/`:

```
plugins/my-new-plugin/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── my-skill/
        ├── SKILL.md
        └── references/
```

2. Add `plugin.json` with at minimum:

```json
{
  "name": "my-new-plugin",
  "description": "What the plugin does",
  "version": "1.0.0"
}
```

3. Add the plugin entry to `marketplace.json`:

```json
{
  "id": "my-new-plugin",
  "name": "My New Plugin",
  "description": "What the plugin does",
  "version": "1.0.0",
  "source": {
    "source": "github",
    "repo": "ResalApps/resal-marketplace",
    "path": "plugins/my-new-plugin"
  }
}
```

4. Test locally, then commit and push.

## Repository structure

```
resal-marketplace/
├── marketplace.json                 # Plugin registry
├── README.md
└── plugins/
    └── add-app-deployment/          # First plugin
        ├── .claude-plugin/
        │   └── plugin.json
        └── skills/
            └── add-app-deployment/
                ├── SKILL.md
                └── references/
                    ├── infrastructure-conventions.md
                    ├── deployment-checklist.md
                    ├── helm-templates.md
                    └── workflow-templates.md
```
