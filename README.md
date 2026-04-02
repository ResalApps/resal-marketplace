# Resal Marketplace

A collection of Claude Code plugins for the Resal DevOps and engineering team. Each plugin encodes repeatable workflows and domain knowledge so any team member can execute complex infrastructure tasks consistently.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [add-app-deployment](plugins/add-app-deployment/) | Add deployment pipeline for new apps (ECR, Helm, ArgoCD, GitHub Actions) |

## Installation

### Step 1: Add the marketplace

```
/plugin marketplace add ResalApps/resal-marketplace
```

### Step 2: Install a plugin

```
/plugin install add-app-deployment@resal
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

3. Add the plugin entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-new-plugin",
  "source": "./plugins/my-new-plugin",
  "description": "What the plugin does"
}
```

4. Test locally, then commit and push.

## Repository structure

```
resal-marketplace/
├── .claude-plugin/
│   └── marketplace.json             # Plugin registry
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
