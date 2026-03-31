# Resal Deployment Plugin

A Claude Code plugin that automates adding deployment pipeline support for new applications to the Resal GitOps infrastructure.

## What it does

When you need to deploy a new app to dev/staging, this plugin handles the full setup:

- **ECR Repository** - Adds Terraform config for the Docker image registry
- **Helm Chart** - Creates the complete chart with all 11 templates, values, and config files
- **ArgoCD Registration** - Registers the app in the app-of-apps for both dev and stage
- **GitHub Actions** - Creates/fixes CI workflows for build, push, and helm sync

## Installation

### Option 1: Install directly from GitHub repo (recommended)

```bash
# Clone the repo and load as a plugin
git clone https://github.com/ResalApps/resal-deployment-plugin.git
claude --plugin-dir ./resal-deployment-plugin
```

Or load it directly in any Claude Code session:

```bash
claude --plugin-dir /path/to/resal-deployment-plugin
```

### Option 2: Install as a user skill (persistent)

Clone the repo into your Claude Code skills directory so it's always available:

```bash
git clone https://github.com/ResalApps/resal-deployment-plugin.git ~/.claude/skills/add-app-deployment
```

To update later:

```bash
cd ~/.claude/skills/add-app-deployment && git pull
```

### Option 3: Install via marketplace

If your team has a Claude Code marketplace configured, add this entry to your `marketplace.json`:

```json
{
  "id": "resal-deployment",
  "name": "Resal Deployment",
  "description": "Add deployment pipelines for new apps",
  "version": "1.0.0",
  "source": {
    "source": "github",
    "repo": "ResalApps/resal-deployment-plugin",
    "path": "."
  }
}
```

Then install:

```bash
claude plugin install resal-deployment@your-marketplace
```

## Usage

### Automatic trigger

The skill triggers automatically when you say things like:

- "Add deployment for my-new-service"
- "Deploy a new app to dev and staging"
- "Onboard payment-gateway to the pipeline"
- "Set up CI/CD for the new frontend"

### Manual trigger

```
/resal-deployment:add-app-deployment
```

Or if installed as a standalone skill:

```
/add-app-deployment
```

### What happens

1. **Gathers info** - Asks you for app name, namespace, ECR path, hostnames, container port, etc.
2. **Plans** - Generates a checklist of all files to create/modify
3. **Executes** - Creates the Helm chart, templates, values files, Terraform config, ArgoCD entries, and CI workflows
4. **Verifies** - Checks all files exist and no stale references remain
5. **PRs** - Creates branches and pull requests in both the infrastructure and app repos

### Post-merge steps

After PRs are merged:

1. Run `terraform apply` in Terraform Cloud `common-infrastructure` workspace
2. Push to the app's `develop` branch to trigger the first dev build
3. ArgoCD auto-syncs the deployment

## Plugin structure

```
resal-deployment-plugin/
├── .claude-plugin/
│   └── plugin.json                              # Plugin manifest
└── skills/
    └── add-app-deployment/
        ├── SKILL.md                             # 5-phase workflow
        └── references/
            ├── infrastructure-conventions.md     # Repo structure, naming, AWS accounts
            ├── deployment-checklist.md           # 8-item creation checklist
            ├── helm-templates.md                 # Helm chart and values templates
            └── workflow-templates.md             # GitHub Actions workflow templates
```

## Requirements

- Access to the `ResalApps/infrastructure` GitHub repository
- `gh` CLI authenticated with appropriate permissions
- `INFRA_REPO_TOKEN` and `COM_AWS_ACCOUNT_ID` secrets configured in the app repo
