# Keycloak & Developer Hub - Terraform Integration Guide

This guide explains how to deploy Keycloak and Developer Hub using Terraform with dynamic configuration based on your cluster's domain.

## Overview

The Terraform integration automatically:
- ✅ Detects your cluster domain dynamically
- ✅ Generates all secrets (OIDC client secret, session secret, ArgoCD token)
- ✅ Processes configuration templates with cluster-specific values
- ✅ Creates ArgoCD applications for GitOps-based deployment
- ✅ Configures Keycloak with correct redirect URIs
- ✅ Sets up Developer Hub with ArgoCD and Tekton plugins

## Quick Start

### 1. Enable the Features

Edit your `terraform.tfvars`:

```hcl
# Enable OpenShift GitOps (required)
deploy_openshift_gitops = true

# Enable Keycloak
deploy_keycloak = true

# Enable Developer Hub (automatically includes Keycloak if not already enabled)
deploy_developerhub = true
```

### 2. Deploy

```bash
cd /Users/sureshgaikwad/terraform/Final_ROSA_Deployment/suresh-rosa-automation

# Initialize Terraform (if first time)
terraform init

# Plan the deployment
terraform plan

# Apply
terraform apply
```

### 3. Access Your Applications

After deployment completes (~10-15 minutes), you'll see output with URLs:

```
Developer Hub: https://backstage-developer-hub-demo-project.apps.<your-cluster-domain>
Keycloak:      https://sample-kc-service-rhbk.apps.<your-cluster-domain>
```

**Default User:**
- Email: `test@gmail.com`
- Username: `myuser`
- Password: Set in Keycloak realm configuration

## Architecture

### Dynamic Configuration Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Terraform Variables                                         │
│ • deploy_keycloak = true                                    │
│ • deploy_developerhub = true                                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Terraform Detects Cluster                                   │
│ • Cluster Domain: apps.rosa.example.a98d.p3.openshiftapps  │
│ • Generates Secrets: OIDC, Session, ArgoCD Token           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Process Templates                                           │
│ • keycloak-client.yaml.template → keycloak-client.yaml     │
│ • auth-secret.yaml.template → auth-secret.yaml             │
│ • app-config.yaml.template → app-config.yaml               │
│                                                             │
│ Replaces:                                                   │
│ • {{CLUSTER_DOMAIN}} → actual domain                       │
│ • {{OIDC_CLIENT_SECRET}} → generated secret                │
│ • {{SESSION_SECRET}} → generated secret                    │
│ • {{ARGOCD_TOKEN}} → generated token                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ Create ArgoCD Applications                                  │
│ • keycloak → operators/keycloak/base                       │
│ • developer-hub → operators/developer-hub/base             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ ArgoCD Syncs Resources                                      │
│ Wave 0: Namespaces                                          │
│ Wave 1: Operators                                           │
│ Wave 2: Keycloak + PostgreSQL                              │
│ Wave 3: Secrets, ConfigMaps, RBAC                          │
│ Wave 4: Developer Hub + PostgreSQL                         │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Files

### Template Files (In Git Repository)

These are templates with placeholders:

| File | Location | Purpose |
|------|----------|---------|
| `keycloak-client.yaml.template` | `operators/keycloak/base/` | Keycloak OIDC client with redirect URIs |
| `auth-secret.yaml.template` | `operators/developer-hub/base/` | Developer Hub authentication secrets |
| `app-config.yaml.template` | `operators/developer-hub/base/` | Developer Hub app configuration |

**Template Placeholders:**
- `{{CLUSTER_DOMAIN}}` - Replaced with actual cluster domain
- `{{OIDC_CLIENT_SECRET}}` - Replaced with generated OIDC secret
- `{{SESSION_SECRET}}` - Replaced with generated session secret
- `{{ARGOCD_TOKEN}}` - Replaced with generated ArgoCD token

### Generated Files

During Terraform execution, templates are processed into:

| File | Generated From | Contains |
|------|----------------|----------|
| `keycloak-client.yaml` | `keycloak-client.yaml.template` | Actual redirect URIs |
| `auth-secret.yaml` | `auth-secret.yaml.template` | Actual secrets |
| `app-config.yaml` | `app-config.yaml.template` | Actual URLs |

## Terraform Resources

### Variables Added

In `variables-features.tf`:

```hcl
variable "deploy_keycloak" {
  type        = bool
  default     = false
  description = "Deploy Red Hat Build of Keycloak (RHBK) via ArgoCD"
}

variable "deploy_developerhub" {
  type        = bool
  default     = false
  description = "Deploy Red Hat Developer Hub via ArgoCD"
}
```

### Resources Created

In `argocd-operator-applications.tf`:

```hcl
# 1. Process templates and deploy Keycloak
resource "null_resource" "create_keycloak_application" {
  count = var.deploy_keycloak && var.deploy_openshift_gitops ? 1 : 0
  # ...
}

# 2. Process templates and deploy Developer Hub
resource "null_resource" "create_developerhub_application" {
  count = var.deploy_developerhub && var.deploy_openshift_gitops ? 1 : 0
  depends_on = [null_resource.create_keycloak_application]
  # ...
}
```

## What Gets Deployed

### Keycloak Stack

- **Namespace:** `rhbk`
- **Operator:** Red Hat Build of Keycloak (RHBK)
- **Database:** PostgreSQL StatefulSet (1Gi storage)
- **Keycloak:** 1 replica
- **Realm:** `myrealm`
- **Client:** `myclient` (OIDC)
- **Users:** Configured in realm

### Developer Hub Stack

- **Namespace:** `demo-project`
- **Operator:** Red Hat Developer Hub (RHDH)
- **Database:** PostgreSQL (local, managed by operator)
- **Developer Hub:** 1 replica
- **Authentication:** Keycloak OIDC
- **Plugins:**
  - ArgoCD (frontend + backend)
  - Tekton
  - Kubernetes (frontend + backend)
- **Catalog:**
  - Default Backstage examples
  - User entities (test@gmail.com)
  - AI Lab templates

## Dependencies

### Automatic Dependencies

Terraform handles these automatically:

```
OpenShift GitOps
       ↓
   Keycloak
       ↓
 Developer Hub
```

### Additional Operators Installed

- **OpenShift Pipelines** - Required for Tekton plugin

## Customization

### Change Keycloak Realm/Client

Edit the static files in `operators/keycloak/base/`:
- `keycloak-realm.yaml` - Modify realm name, users, settings
- `keycloak-client.yaml.template` - Modify client ID (keep template placeholders)

### Change Developer Hub Settings

Edit the template file:
- `operators/developer-hub/base/app-config.yaml.template`

Keep these placeholders intact:
- `{{CLUSTER_DOMAIN}}`
- `${AUTH_OIDC_CLIENT_ID}` (environment variable)
- `${AUTH_OIDC_CLIENT_SECRET}` (environment variable)

### Add More Users

Edit `operators/developer-hub/base/user-entities.yaml`:

```yaml
---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: newuser
spec:
  profile:
    displayName: New User
    email: newuser@example.com  # Must match Keycloak user
  memberOf: []
```

Then add the user to Keycloak in `keycloak-realm.yaml`.

### Change Secrets

Secrets are generated automatically. To use custom secrets:

1. Modify the Terraform script in `argocd-operator-applications.tf`
2. Replace `openssl rand -base64 32` with your secret

**Example:**
```bash
# In the Terraform script
OIDC_CLIENT_SECRET="your-custom-secret"
SESSION_SECRET="your-custom-session-secret"
```

## Verification

### Check ArgoCD Applications

```bash
# List applications
oc get application -n openshift-gitops

# Check Keycloak app status
oc get application keycloak -n openshift-gitops -o yaml

# Check Developer Hub app status
oc get application developer-hub -n openshift-gitops -o yaml
```

### Check Deployments

```bash
# Keycloak
oc get pods -n rhbk
oc get keycloak -n rhbk
oc get route -n rhbk

# Developer Hub
oc get pods -n demo-project
oc get backstage -n demo-project
oc get route -n demo-project
```

### Check Secrets

```bash
# Keycloak client secret
oc get secret -n rhbk

# Developer Hub secrets
oc get secret developer-hub-auth-secrets -n demo-project -o yaml
```

### Access Applications

```bash
# Get URLs
CLUSTER_DOMAIN=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}')

echo "Developer Hub: https://backstage-developer-hub-demo-project.$CLUSTER_DOMAIN"
echo "Keycloak: https://sample-kc-service-rhbk.$CLUSTER_DOMAIN"
```

## Troubleshooting

### Issue: Templates Not Processed

**Symptoms:**
- ArgoCD shows sync errors
- Configuration still has `{{CLUSTER_DOMAIN}}` placeholders

**Solution:**
```bash
# Check Terraform output
terraform apply -target=null_resource.create_keycloak_application

# Manually process templates
cd /Users/sureshgaikwad/terraform/Final_ROSA_Deployment/gitops-catalog
CLUSTER_DOMAIN=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}')

# Process Keycloak templates
cd operators/keycloak/base
sed -i "s|{{CLUSTER_DOMAIN}}|$CLUSTER_DOMAIN|g" keycloak-client.yaml

# Process Developer Hub templates
cd ../../developer-hub/base
sed -i "s|{{CLUSTER_DOMAIN}}|$CLUSTER_DOMAIN|g" app-config.yaml
sed -i "s|{{CLUSTER_DOMAIN}}|$CLUSTER_DOMAIN|g" auth-secret.yaml
```

### Issue: OIDC Client Secret Mismatch

**Symptoms:**
- Login fails with authentication error
- Developer Hub logs show "invalid client secret"

**Solution:**
```bash
# Get the secret used in Keycloak
KC_SECRET=$(oc get keycloakrealmimport myrealm-client-import -n rhbk -o jsonpath='{.spec.realm.clients[0].secret}')

# Update Developer Hub secret
oc patch secret developer-hub-auth-secrets -n demo-project \
  -p "{\"stringData\":{\"AUTH_OIDC_CLIENT_SECRET\":\"$KC_SECRET\"}}"

# Restart Developer Hub
oc rollout restart deployment/backstage-developer-hub -n demo-project
```

### Issue: ArgoCD Token Invalid

**Symptoms:**
- ArgoCD plugin shows "unauthorized"
- Cannot view ArgoCD applications in Developer Hub

**Solution:**
```bash
# Generate new token
ARGOCD_TOKEN=$(oc create token openshift-gitops-argocd-server -n openshift-gitops --duration=87600h)

# Update Developer Hub secret
oc patch secret developer-hub-auth-secrets -n demo-project \
  -p "{\"stringData\":{\"ARGOCD_AUTH_TOKEN\":\"$ARGOCD_TOKEN\"}}"

# Restart Developer Hub
oc rollout restart deployment/backstage-developer-hub -n demo-project
```

### Issue: Pods Not Starting

**Symptoms:**
- Pods in `CrashLoopBackOff`
- ImagePullBackOff errors

**Solution:**
```bash
# Check pod logs
oc logs -f deployment/backstage-developer-hub -n demo-project

# Check operator logs
oc logs -f deployment/rhbk-operator -n rhbk
oc logs -f deployment/rhdh-operator -n demo-project

# Check events
oc get events -n demo-project --sort-by='.lastTimestamp'
oc get events -n rhbk --sort-by='.lastTimestamp'
```

## Cleanup

### Destroy Everything

```bash
# In Terraform directory
terraform destroy
```

### Destroy Only Developer Hub

```bash
terraform destroy -target=null_resource.create_developerhub_application
oc delete application developer-hub -n openshift-gitops
```

### Destroy Only Keycloak

```bash
terraform destroy -target=null_resource.create_keycloak_application
oc delete application keycloak -n openshift-gitops
```

## Production Considerations

### 1. Secrets Management

**Current:** Secrets generated and stored in Git
**Production:** Use external secrets manager

Options:
- AWS Secrets Manager
- HashiCorp Vault
- OpenShift External Secrets Operator

### 2. Database

**Current:** Local PostgreSQL in StatefulSet
**Production:** Use managed database

Options:
- AWS RDS PostgreSQL
- Azure Database for PostgreSQL
- Google Cloud SQL

Update `keycloak-instance.yaml` and `backstage-instance.yaml` to use external DB.

### 3. TLS Certificates

**Current:** Self-signed certificates
**Production:** Use valid certificates

Options:
- Let's Encrypt via cert-manager
- Corporate CA certificates
- AWS Certificate Manager

Remove these settings:
- `NODE_TLS_REJECT_UNAUTHORIZED: "0"`
- `dangerouslyAllowInsecureHttpRequests: true`

### 4. High Availability

**Current:** 1 replica each
**Production:** Multiple replicas

Update:
```yaml
# Keycloak
spec:
  instances: 3

# Developer Hub
spec:
  application:
    replicas: 3
```

### 5. RBAC

**Current:** RBAC disabled
**Production:** Enable proper RBAC

Edit `operators/developer-hub/base/rbac.yaml` with proper policies.

## Advanced Usage

### Deploy to Multiple Environments

Use Terraform workspaces:

```bash
# Create dev environment
terraform workspace new dev
terraform apply -var-file=dev.tfvars

# Create prod environment
terraform workspace new prod
terraform apply -var-file=prod.tfvars
```

### Custom Git Repository

Change the repository in `terraform.tfvars`:

```hcl
gitops_repo_url = "https://github.com/your-org/your-gitops-repo"
```

Ensure your repository has the same structure under `operators/`.

### Override Default Settings

Create a `terraform.tfvars`:

```hcl
deploy_keycloak     = true
deploy_developerhub = true
gitops_repo_url     = "https://github.com/myorg/gitops"
```

## References

- [Red Hat Build of Keycloak Documentation](https://access.redhat.com/documentation/en-us/red_hat_build_of_keycloak)
- [Red Hat Developer Hub Documentation](https://access.redhat.com/documentation/en-us/red_hat_developer_hub)
- [OpenShift GitOps Documentation](https://docs.openshift.com/gitops/)
- [Terraform OpenShift Provider](https://registry.terraform.io/providers/terraform-redhat/rhcs/latest/docs)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review ArgoCD application logs
3. Check operator logs
4. Review OpenShift events

---

**Part of the ROSA Automation Terraform Module**

