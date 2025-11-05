# Developer Hub Configuration Templates

## Dynamic Configuration

This directory contains **template files** that are processed by Terraform to generate cluster-specific configurations.

### Template Files

- **auth-secret.yaml.template** - Authentication secrets template
- **app-config.yaml.template** - Application configuration template

### Generated Files (Not in Git)

These files are generated automatically by Terraform:

- **auth-secret.yaml** - Generated with actual secrets and URLs
- **app-config.yaml** - Generated with actual cluster domain

### How It Works

1. **Terraform detects** your cluster domain automatically
2. **Generates secrets**:
   - OIDC client secret (from Keycloak deployment)
   - Session secret (random)
   - ArgoCD token (service account token)
3. **Processes templates** replacing placeholders with actual values
4. **Creates YAML files** with real configuration
5. **Commits and pushes** to this repository
6. **ArgoCD syncs** the generated configuration

### Placeholders in Templates

| Placeholder | Replaced With | Example |
|-------------|---------------|---------|
| `{{CLUSTER_DOMAIN}}` | Cluster ingress domain | `apps.rosa.example.com` |
| `{{OIDC_CLIENT_SECRET}}` | Keycloak client secret | `xyz789...` |
| `{{SESSION_SECRET}}` | Session encryption secret | `abc123...` |
| `{{ARGOCD_TOKEN}}` | ArgoCD API token | `eyJhbGci...` |

### URLs Generated

From templates, these URLs are generated:

- **Developer Hub**: `https://backstage-developer-hub-demo-project.{{CLUSTER_DOMAIN}}`
- **Keycloak**: `https://sample-kc-service-rhbk.{{CLUSTER_DOMAIN}}`
- **ArgoCD**: `https://openshift-gitops-server-openshift-gitops.{{CLUSTER_DOMAIN}}`

### Manual Deployment

If deploying manually without Terraform:

```bash
# Get cluster domain
CLUSTER_DOMAIN=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}')

# Get/Generate secrets
OIDC_SECRET="<from-keycloak-deployment>"
SESSION_SECRET=$(openssl rand -base64 32)
ARGOCD_TOKEN=$(oc create token openshift-gitops-argocd-server -n openshift-gitops --duration=87600h)

# Process auth-secret template
sed -e "s|{{CLUSTER_DOMAIN}}|$CLUSTER_DOMAIN|g" \
    -e "s|{{OIDC_CLIENT_SECRET}}|$OIDC_SECRET|g" \
    -e "s|{{SESSION_SECRET}}|$SESSION_SECRET|g" \
    -e "s|{{ARGOCD_TOKEN}}|$ARGOCD_TOKEN|g" \
    auth-secret.yaml.template > auth-secret.yaml

# Process app-config template
sed "s|{{CLUSTER_DOMAIN}}|$CLUSTER_DOMAIN|g" \
    app-config.yaml.template > app-config.yaml

# Deploy
oc apply -k .
```

### Why Not Commit Generated Files?

- **Portability**: Works on any cluster without modification
- **Security**: Secrets are unique per deployment
- **Automation**: Terraform handles everything
- **No hardcoding**: Domain and secrets are detected/generated

### Integration with Keycloak

The `OIDC_CLIENT_SECRET` must match the secret configured in Keycloak. Terraform ensures this by:

1. Generating the secret once
2. Using it in Keycloak client configuration
3. Using the same secret in Developer Hub auth configuration

---

**Generated files are listed in `.gitignore` to prevent accidental commits.**

