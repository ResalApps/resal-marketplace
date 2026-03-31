# Deployment Checklist

For each new app, these items must be created or modified. Replace `{app-name}`, `{namespace}`, `{ecr-path}`, `{github-repo}`, `{dev-host}`, `{stage-host}` with actual values.

## Infrastructure Repo Changes

### 1. ECR Repository (Terraform)

**File:** `terraform/common/main.tf`
**Action:** Add entry inside the `ecrs` map:

```hcl
"{ecr-path}" = {
  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = false
}
```

### 2. Helm Chart Directory

**Create:** `apps/{namespace}/{app-name}/`

Files to create:
- `Chart.yaml` - Chart metadata with postgresql dependency
- `.helmignore` - Standard ignore patterns

### 3. Helm Templates

**Create:** `apps/{namespace}/{app-name}/templates/`

All 11 template files (see [helm-templates.md](helm-templates.md)):
- `_helpers.tpl` - Template functions (name, labels, selectors, ALB cert, ALB group)
- `deployment.yaml` - Deployment manifest
- `service.yaml` - Service manifest
- `ingress.yaml` - ALB Ingress manifest
- `configmap.yaml` - ConfigMap for runtime env vars
- `hpa.yaml` - HorizontalPodAutoscaler
- `serviceaccount.yaml` - ServiceAccount
- `onepassworditem.yaml` - 1Password secret references
- `volumes-onepassworditem.yaml` - 1Password volume secrets
- `postgresql-onepassworditem.yaml` - PostgreSQL 1Password item
- `NOTES.txt` - Helm install notes

**Critical:** Every template helper reference must use `{app-name}` prefix (e.g., `include "{app-name}.name"`).

### 4. Dev Environment Values

**Create:**
- `apps/{namespace}/{app-name}/values-dev.yaml` - Structural config
- `apps/{namespace}/{app-name}/config-dev.yaml` - Image tag + configmap data

Key settings:
- `environment: "dev"`
- `image.repository: "882222437772.dkr.ecr.us-east-2.amazonaws.com/{ecr-path}"`
- `image.tag: "dev.1.1.0"`
- `service.containerPort: {port}`
- `ingress.hosts[0].host: "{dev-host}"`
- `onepassword.vault: "dev-cluster"`

### 5. Stage Environment Values

**Create:**
- `apps/{namespace}/{app-name}/values-stage.yaml` - Structural config
- `apps/{namespace}/{app-name}/config-stage.yaml` - Image tag + configmap data

Same as dev but with:
- `environment: "stage"`
- `image.tag: "stage.1.1.0"`
- `ingress.hosts[0].host: "{stage-host}"`
- `onepassword.vault: "stage-cluster"`

### 6. ArgoCD Registration

**Modify:** `app-of-apps/values-dev.yaml` and `app-of-apps/values-stage.yaml`

Add entry in the appropriate namespace section:

```yaml
- name: {app-name}
  namespace: {namespace}
  info:
    name: "GitHub Repository:"
    value: "https://github.com/ResalApps/{github-repo}"
  ignoreDifferences:
    - group: ""
      kind: Secret
      jsonPointers:
        - /data/ca.crt
        - /data/tls.crt
        - /data/tls.key
```

## App Repo Changes

### 7. CI Workflows

**Create or fix** in the app repository's `.github/workflows/`:

- **Dev build workflow** - Triggers on `develop` branch, uses `docker-build-push.yaml`
- **Stage build workflow** - Triggers on `stage` branch, uses `docker-build-push.yaml`
- **Helm sync workflow** - Triggers on helm config changes, uses `sync-helm-chart.yaml`

All must reference the correct `ecr_repository`, `app_name`, and `namespace`.

### 8. Helm Config Files (in app repo)

**Create** in the app repository's `helm/` directory:
- `helm/config-dev.yaml` - Dev image tag + configmap skeleton
- `helm/config-stage.yaml` - Stage image tag + configmap skeleton

These are the files that CI auto-updates with new image tags.

## Verification Checklist

- [ ] `find apps/{namespace}/{app-name} -type f | sort` shows all expected files
- [ ] `grep "{app-name}" app-of-apps/values-dev.yaml` finds the ArgoCD entry
- [ ] `grep "{app-name}" app-of-apps/values-stage.yaml` finds the ArgoCD entry
- [ ] `grep "{ecr-path}" terraform/common/main.tf` finds the ECR entry
- [ ] No stale references from copied templates (grep for old app names)
- [ ] CI workflows reference correct `ecr_repository`, `app_name`, `namespace`
