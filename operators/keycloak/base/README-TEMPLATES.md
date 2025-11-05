# Keycloak Configuration Templates

## Dynamic Configuration

This directory contains **template files** that are processed by Terraform to generate cluster-specific configurations.

### Template Files

- **keycloak-client.yaml.template** - OIDC client configuration template

### Generated Files (Not in Git)

These files are generated automatically by Terraform:

- **keycloak-client.yaml** - Generated from template with actual cluster domain

### How It Works

1. **Terraform detects** your cluster domain automatically
2. **Processes template** replacing `{{CLUSTER_DOMAIN}}` with actual domain
3. **Generates secrets** (OIDC client secret)
4. **Creates YAML file** with real values
5. **Commits and pushes** to this repository
6. **ArgoCD syncs** the generated configuration

### Placeholders in Templates

| Placeholder | Replaced With | Example |
|-------------|---------------|---------|
| `{{CLUSTER_DOMAIN}}` | Cluster ingress domain | `apps.rosa.example.com` |
| `{{OIDC_CLIENT_SECRET}}` | Generated secret | `abc123...` |

### Manual Deployment

If deploying manually without Terraform:

```bash
# Get cluster domain
CLUSTER_DOMAIN=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}')

# Generate secret
OIDC_SECRET=$(openssl rand -base64 32)

# Process template
sed -e "s|{{CLUSTER_DOMAIN}}|$CLUSTER_DOMAIN|g" \
    -e "s|{{OIDC_CLIENT_SECRET}}|$OIDC_SECRET|g" \
    keycloak-client.yaml.template > keycloak-client.yaml

# Deploy
oc apply -k .
```

### Why Not Commit Generated Files?

- **Portability**: Works on any cluster without modification
- **Security**: Secrets are generated per deployment
- **Automation**: Terraform handles everything
- **No hardcoding**: Domain is detected, not hardcoded

---

**Generated files are listed in `.gitignore` to prevent accidental commits.**

