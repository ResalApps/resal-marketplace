# GitHub Actions Workflow Templates

Replace `{APP_NAME}`, `{ECR_PATH}`, `{NAMESPACE}` with actual values.

## Dev Build Workflow

**File:** `.github/workflows/dev-cluster-ci.yaml`

```yaml
name: "[Dev] Build And Push {APP_NAME} to ECR"
on:
  push:
    branches:
      - "develop"
    paths-ignore:
      - "helm/**"
    tags-ignore:
      - "dev.1.1.*"
      - "stage.1.1.*"
      - "prod.1.1.*"
  workflow_dispatch:

permissions:
  id-token: write
  contents: write

jobs:
  call-build-push-action:
    uses: ResalApps/infrastructure/.github/workflows/docker-build-push.yaml@main
    with:
      iam_role_name: "github-actions-ecr-role"
      ecr_repository: "{ECR_PATH}"
      environment: "dev"
    secrets:
      aws_account_id: ${{ secrets.COM_AWS_ACCOUNT_ID }}
      infra_repo_token: ${{ secrets.INFRA_REPO_TOKEN }}
```

To add Docker build-args (e.g., for Next.js NEXT_PUBLIC_* vars):

```yaml
    with:
      iam_role_name: "github-actions-ecr-role"
      ecr_repository: "{ECR_PATH}"
      environment: "dev"
      build-args: |
        NEXT_PUBLIC_GRAPHQL_URL=${{ vars.DEV_GRAPHQL_URL }}
        NEXT_PUBLIC_SITE_URL=${{ vars.DEV_SITE_URL }}
```

## Stage Build Workflow

**File:** `.github/workflows/stage-cluster-ci.yaml`

Same as dev but with:
- `branches: ["stage"]`
- `environment: "stage"`
- Name: `"[Stage] Build And Push {APP_NAME} to ECR"`

## Helm Config Sync Workflow

**File:** `.github/workflows/sync-helm-chart-configs.yaml`

```yaml
name: Sync Helm Chart Configs
on:
  push:
    paths:
      - "helm/config-dev.yaml"
      - "helm/config-stage.yaml"
      - "helm/config-prod.yaml"
    branches:
      - "develop"
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  call-build-push-action:
    uses: ResalApps/infrastructure/.github/workflows/sync-helm-chart.yaml@main
    with:
      app_name: {APP_NAME}
      namespace: {NAMESPACE}
      repo_name: ${{ github.event.repository.name }}
    secrets:
      INFRA_REPO_TOKEN: ${{ secrets.INFRA_REPO_TOKEN }}
```

## App Repo Helm Config Files

### helm/config-dev.yaml

```yaml
image:
  tag: "dev.1.1.0"
configmap:
  create: true
  data: {}
onepassword:
  vault: "dev-cluster"
  secrets: {}
  volumes: []
```

### helm/config-stage.yaml

```yaml
image:
  tag: "stage.1.1.0"
configmap:
  create: true
  data: {}
onepassword:
  vault: "stage-cluster"
  secrets: {}
  volumes: []
```
