# GitHub Actions Workflow Templates

Replace `{APP_NAME}`, `{ECR_PATH}`, `{NAMESPACE}`, `{GITHUB_REPO}` with actual values.

> **Important:** Reusable workflows must be referenced as `@main` (not pinned SHA) so apps automatically pick up fixes to the shared CI/CD pipeline.

## Dev Build Workflow

**File:** `.github/workflows/dev-cluster-ci-{COMPONENT}.yaml`

For multi-component repos (e.g., a repo with both `backend/` and `frontend/`), create one workflow per component:
- `.github/workflows/dev-cluster-ci-backend.yaml`
- `.github/workflows/dev-cluster-ci-frontend.yaml`

```yaml
name: "[Dev] Build And Push {APP_NAME} to ECR"
on:
  push:
    branches:
      - "develop"
    paths:
      - "{COMPONENT}/**"       # e.g., "backend/**" or "frontend/**"
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
      docker-context: "./{COMPONENT}"
      dockerfile_path: "./{COMPONENT}/Dockerfile"
      helm_values_file: "helm/{APP_NAME}/config-dev.yaml"
    secrets:
      aws_account_id: ${{ secrets.COM_AWS_ACCOUNT_ID }}
      infra_repo_token: ${{ secrets.INFRA_REPO_TOKEN }}
```

> **Critical:** Always include `helm_values_file` pointing to the app-specific path `helm/{APP_NAME}/config-{env}.yaml`. Without it, the update job falls back to a flat `helm/config-{env}.yaml` path that doesn't exist for multi-component repos.

To add Docker build-args (e.g., for Next.js NEXT_PUBLIC_* vars):

```yaml
    with:
      iam_role_name: "github-actions-ecr-role"
      ecr_repository: "{ECR_PATH}"
      environment: "dev"
      docker-context: "./{COMPONENT}"
      dockerfile_path: "./{COMPONENT}/Dockerfile"
      helm_values_file: "helm/{APP_NAME}/config-dev.yaml"
      build-args: |
        NEXT_PUBLIC_API_URL=${{ vars.DEV_API_URL }}
```

## Stage Build Workflow

**File:** `.github/workflows/stage-cluster-ci-{COMPONENT}.yaml`

Same as dev but with:
- `branches: ["stage"]`
- `environment: "stage"`
- `helm_values_file: "helm/{APP_NAME}/config-stage.yaml"`
- Name: `"[Stage] Build And Push {APP_NAME} to ECR"`

## Helm Config Sync Workflow

**File:** `.github/workflows/sync-helm-chart-configs-{COMPONENT}.yaml`

For multi-component repos, create one sync workflow per component. The sync workflow triggers when the CI updates the helm config file with a new image tag.

```yaml
name: Sync Helm Chart Configs ({COMPONENT})
on:
  push:
    paths:
      - "helm/{APP_NAME}/config-dev.yaml"
      - "helm/{APP_NAME}/config-stage.yaml"
      - "helm/{APP_NAME}/config-prod.yaml"
    branches:
      - "develop"
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  call-sync-action:
    uses: ResalApps/infrastructure/.github/workflows/sync-helm-chart.yaml@main
    with:
      app_name: {APP_NAME}
      namespace: {NAMESPACE}
      repo_name: ${{ github.event.repository.name }}
    secrets:
      INFRA_REPO_TOKEN: ${{ secrets.INFRA_REPO_TOKEN }}
```

> **Note:** The sync workflow in the infrastructure repo automatically detects whether the app repo uses a nested `helm/{app_name}/` structure or a flat `helm/` structure, and copies only `config-*.yaml` files (not subdirectories).

## App Repo Helm Config Files

Config files live under `helm/{APP_NAME}/` (one directory per deployable component):

### helm/{APP_NAME}/config-dev.yaml

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

### helm/{APP_NAME}/config-stage.yaml

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
