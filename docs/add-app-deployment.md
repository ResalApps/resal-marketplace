# Add App Deployment

Add full deployment pipeline support for a new application to the Resal GitOps infrastructure.

## Table of Contents

- [Overview](#overview)
- [What It Does](#what-it-does)
- [Prerequisites](#prerequisites)
- [How to Use](#how-to-use)
  - [Trigger the Plugin](#trigger-the-plugin)
  - [Information You'll Need](#information-youll-need)
- [Workflow](#workflow)
  - [Phase 1: Gather Information](#phase-1-gather-information)
  - [Phase 2: Plan](#phase-2-plan)
  - [Phase 3: Execute](#phase-3-execute)
  - [Phase 4: Verify](#phase-4-verify)
  - [Phase 5: Commit & PR](#phase-5-commit--pr)
- [What Gets Created](#what-gets-created)
  - [Infrastructure Repo Changes](#infrastructure-repo-changes)
  - [App Repo Changes](#app-repo-changes)
- [Post-Merge Steps](#post-merge-steps)
- [Example Session](#example-session)
- [Infrastructure Reference](#infrastructure-reference)

---

## Overview

| | |
|---|---|
| **Plugin name** | `add-app-deployment` |
| **Slash command** | `/add-app-deployment:add-app-deployment` |
| **Triggers on** | "add deployment for X", "deploy a new service", "onboard a new microservice", "set up CI/CD for a new app" |
| **Repos modified** | `ResalApps/infrastructure` + the app's own repo |
| **Environments** | Dev and Staging |

## What It Does

This plugin automates the entire process of adding a new application to the Resal deployment pipeline. It creates or modifies files across two repositories:

1. **Infrastructure repo** (`ResalApps/infrastructure`) - ECR registry, Helm chart, ArgoCD registration
2. **App repo** - GitHub Actions CI/CD workflows

Without this plugin, onboarding a new app requires manually creating ~20 files across both repos, following exact naming conventions, and ensuring consistency with the existing infrastructure patterns. This plugin handles all of that automatically.

## Prerequisites

- Access to the `ResalApps` GitHub organization
- `gh` CLI authenticated with appropriate permissions
- The infrastructure repo cloned locally (the plugin will clone it if not found)
- GitHub secrets configured in the app repo:
  - `COM_AWS_ACCOUNT_ID` - The shared ECR AWS account ID
  - `INFRA_REPO_TOKEN` - A token with write access to the infrastructure repo

## How to Use

### Trigger the Plugin

**Option 1: Natural language** - Just describe what you need:

> "Add deployment support for my-new-service to dev and staging"

> "Set up the CI/CD pipeline for the new payment-gateway app"

> "Onboard resal-store-frontend to the deployment pipeline"

**Option 2: Slash command:**

```
/add-app-deployment:add-app-deployment
```

### Information You'll Need

The plugin will ask you for these details before starting:

| # | Input | Description | Example |
|---|-------|-------------|---------|
| 1 | App name | Kubernetes-friendly name | `store-frontend` |
| 2 | Namespace | K8s namespace group | `resal-app`, `core`, `business-solutions` |
| 3 | ECR path | Docker image registry path | `resal-app/resal-store-frontend` |
| 4 | GitHub repo | App's GitHub repository name | `resal-store-frontend` |
| 5 | Dev hostname | Ingress URL for dev | `store-dev.myresal.com` |
| 6 | Stage hostname | Ingress URL for staging | `store-stg.myresal.com` |
| 7 | Container port | Port the app listens on | `3000` (frontend), `8080` (backend) |
| 8 | Component type | App classification | `frontend`, `backend`, `api` |
| 9 | ConfigMap data | Runtime environment variables | `MOBILE_VERSION`, `CS_INTEGRATION_WEB` |
| 10 | 1Password secrets | Secrets from 1Password vaults | `{}` (none) or key-value pairs |
| 11 | Resources | CPU/memory requests | `100m/128Mi` |
| 12 | CI branches | Branches that trigger builds | `develop` (dev), `stage` (staging) |
| 13 | Build args | Docker build arguments | `NEXT_PUBLIC_*` vars for Next.js apps |

## Workflow

### Phase 1: Gather Information

The plugin collects the inputs listed above through an interactive Q&A. It provides sensible defaults where possible (e.g., `100m/128Mi` for resources, `develop`/`stage` for CI branches).

### Phase 2: Plan

A concrete implementation plan is generated listing every file to create or modify. You review the plan before any changes are made.

### Phase 3: Execute

The plugin creates all files following the exact patterns established in the infrastructure repo:

- Terraform ECR entry
- Helm chart with 11 standardized templates
- Environment-specific values and config files
- ArgoCD app-of-apps registration
- GitHub Actions CI/CD workflows

### Phase 4: Verify

Automated checks confirm:
- All expected files exist
- No stale references from copy-paste errors
- ArgoCD entries present in both dev and stage
- ECR entry exists in Terraform
- CI workflows reference the correct ECR repo, app name, and namespace

### Phase 5: Commit & PR

The plugin creates a feature branch (`feat/add-{app-name}-deployment`) in each repo, commits the changes, pushes, and creates pull requests.

## What Gets Created

### Infrastructure Repo Changes

```
infrastructure/
├── terraform/common/main.tf                          # + ECR repository entry
├── app-of-apps/
│   ├── values-dev.yaml                               # + ArgoCD app entry (dev)
│   └── values-stage.yaml                             # + ArgoCD app entry (stage)
└── apps/{namespace}/{app-name}/
    ├── Chart.yaml                                    # Helm chart metadata
    ├── .helmignore                                   # Helm ignore patterns
    ├── values-dev.yaml                               # Dev structural config
    ├── config-dev.yaml                               # Dev image tag + configmap
    ├── values-stage.yaml                             # Stage structural config
    ├── config-stage.yaml                             # Stage image tag + configmap
    └── templates/
        ├── _helpers.tpl                              # Template functions
        ├── deployment.yaml                           # K8s Deployment
        ├── service.yaml                              # K8s Service
        ├── ingress.yaml                              # ALB Ingress
        ├── configmap.yaml                            # ConfigMap
        ├── hpa.yaml                                  # HorizontalPodAutoscaler
        ├── serviceaccount.yaml                       # ServiceAccount
        ├── onepassworditem.yaml                      # 1Password secrets
        ├── volumes-onepassworditem.yaml              # 1Password volume secrets
        ├── postgresql-onepassworditem.yaml           # PostgreSQL 1Password
        └── NOTES.txt                                 # Install notes
```

### App Repo Changes

```
app-repo/
└── .github/workflows/
    ├── dev-cluster-ci.yaml                           # Dev build + push to ECR
    ├── stage-cluster-ci.yaml                         # Stage build + push to ECR
    └── sync-helm-chart-configs.yaml                  # Helm config sync to infra repo
```

## Post-Merge Steps

After the pull requests are merged, complete these manual steps:

1. **Terraform apply** - Run in Terraform Cloud `common-infrastructure` workspace to create the ECR repository
2. **Merge infrastructure PR** - ArgoCD will discover the new application (will wait for an image)
3. **Merge app repo PR** - Push to `develop` triggers the first build, pushing an image to ECR
4. **ArgoCD syncs** - Detects the new image tag and deploys the pod

## Example Session

```
User: "Add deployment for resal-store-frontend to dev and staging"

Claude: I'll use the add-app-deployment skill. I need some information:
  1. App name? → resal-store-frontend
  2. Namespace? → resal-app
  3. ECR path? → resal-app/resal-store-frontend
  4. Dev hostname? → store-dev.myresal.com
  5. Stage hostname? → store-stg.myresal.com
  6. Container port? → 3000
  ...

Claude: Here's the implementation plan with 8 tasks...
  [Creates all files, verifies, commits, opens PRs]

Claude: Done! PRs created:
  - infrastructure: ResalApps/infrastructure#533
  - app repo: ResalApps/resal-store-frontend#4
```

## Infrastructure Reference

The plugin uses these infrastructure patterns:

| Component | Pattern |
|-----------|---------|
| ECR image | `882222437772.dkr.ecr.us-east-2.amazonaws.com/{namespace}/{app-name}` |
| Image tag | `{env}.1.1.{github_run_number}` |
| Helm helpers | `{app-name}.name`, `{app-name}.labels`, `{app-name}.chart` |
| 1Password vault | `dev-cluster` (dev), `stage-cluster` (stage) |
| ALB group | `dev` (dev), `stage` (stage) |
| CI workflow | `ResalApps/infrastructure/.github/workflows/docker-build-push.yaml@main` |
| Helm sync | `ResalApps/infrastructure/.github/workflows/sync-helm-chart.yaml@main` |
| Infra repo | `https://github.com/ResalApps/infrastructure.git` (branch: `main`) |
