# Infrastructure Conventions

## Repository Structure

```
infrastructure/
├── app-of-apps/                 # ArgoCD Application-of-Applications
│   ├── Chart.yaml
│   ├── templates/application.yaml
│   ├── values-dev.yaml          # Dev environment app definitions
│   └── values-stage.yaml        # Stage environment app definitions
├── apps/                        # Helm charts per namespace
│   ├── core/                    # Core microservices
│   ├── business-solutions/      # Business solution services
│   ├── merchant-solutions/      # Merchant platform services
│   ├── resal-admin/             # Admin platform
│   ├── resal-app/               # Store/consumer platform
│   └── ...                      # Infrastructure services
├── terraform/
│   ├── common/main.tf           # ECR repository definitions
│   ├── development/main.tf      # Dev EKS cluster
│   └── staging/main.tf          # Staging EKS cluster
└── .github/workflows/
    ├── docker-build-push.yaml   # Reusable: build + scan + push to ECR
    └── sync-helm-chart.yaml     # Reusable: sync helm values to infra repo
```

## Per-App Directory Structure

Each app lives at `apps/{namespace}/{app-name}/`:

```
apps/{namespace}/{app-name}/
├── Chart.yaml
├── .helmignore
├── values-dev.yaml        # Dev environment values
├── config-dev.yaml        # Dev image tag + configmap data
├── values-stage.yaml      # Stage environment values
├── config-stage.yaml      # Stage image tag + configmap data
└── templates/
    ├── _helpers.tpl
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── configmap.yaml
    ├── hpa.yaml
    ├── serviceaccount.yaml
    ├── onepassworditem.yaml
    ├── volumes-onepassworditem.yaml
    ├── postgresql-onepassworditem.yaml
    └── NOTES.txt
```

## Two-Layer Configuration

- **values-{env}.yaml** - Structural config (image repo, resources, ingress, service, strategy)
- **config-{env}.yaml** - Mutable config (image tag, configmap data, 1Password secrets)

ArgoCD loads both via Helm value files. The `config-*.yaml` is auto-updated by CI.

## Naming Conventions

- ECR repository: `{namespace}/{app-name}` (e.g., `resal-app/resal-store-frontend`)
- Image: `882222437772.dkr.ecr.us-east-2.amazonaws.com/{namespace}/{app-name}`
- Image tag: `{env}.1.1.{github_run_number}` (e.g., `dev.1.1.156`)
- Helm template helpers: `{app-name}.name`, `{app-name}.labels`, `{app-name}.chart`, etc.
- 1Password vault: `dev-cluster` (dev), `stage-cluster` (stage)

## AWS Accounts

- `244122818208` - Development account
- `882222437772` - ECR account (shared)
- `904871342989` - Staging account

## ArgoCD App-of-Apps

The `app-of-apps/templates/application.yaml` template auto-discovers apps by:
- Using the path `apps/{namespace}/{app-name}` from the `values-{env}.yaml` entry
- Loading `values-{env}.yaml` and `config-{env}.yaml` as Helm value files
- Namespaces `core`, `business-solutions`, `resal-app`, `resal-admin`, `merchant-solutions` get config files loaded

## CI/CD Flow

```
App Repo push -> GitHub Actions -> Build Docker image -> Trivy scan -> Push to ECR
-> Update helm/config-{env}.yaml with new tag -> Commit back to app repo
-> sync-helm-chart workflow -> Copy helm/ to infrastructure repo -> ArgoCD syncs
```

## Reusable Workflows

### docker-build-push.yaml

Inputs: `iam_role_name`, `ecr_repository`, `environment`, `dockerfile_path`, `build-args`
Secrets: `aws_account_id` (`COM_AWS_ACCOUNT_ID`), `infra_repo_token` (`INFRA_REPO_TOKEN`)

### sync-helm-chart.yaml

Inputs: `app_name`, `repo_name`, `namespace`
Secrets: `INFRA_REPO_TOKEN`

Auto-commits dev files directly, creates PRs for stage/prod files.
