# Keycloak & Developer Hub - Deployment Summary

## ✅ Configuration Complete!

All configurations have been split into separate directories and integrated with Terraform for dynamic, domain-agnostic deployment.

## 📁 Directory Structure

```
/Users/sureshgaikwad/terraform/Final_ROSA_Deployment/
│
├── gitops-catalog/operators/
│   ├── keycloak/
│   │   ├── base/
│   │   │   ├── keycloak-client.yaml.template    ← Dynamic template
│   │   │   ├── keycloak-client.yaml             ← Static (for manual use)
│   │   │   ├── keycloak-instance.yaml           ← Static
│   │   │   ├── keycloak-realm.yaml              ← Static
│   │   │   ├── keycloak-db-secret.yaml          ← Static
│   │   │   ├── rhbk-namespace.yaml              ← Static
│   │   │   ├── rhbk-operator.yaml               ← Static
│   │   │   └── kustomization.yaml               ← Kustomize config
│   │   ├── overlays/production/
│   │   └── README.md                            ← Keycloak docs
│   │
│   ├── developer-hub/
│   │   ├── base/
│   │   │   ├── auth-secret.yaml.template        ← Dynamic template
│   │   │   ├── auth-secret.yaml                 ← Static (for manual use)
│   │   │   ├── app-config.yaml.template         ← Dynamic template
│   │   │   ├── app-config.yaml                  ← Static (for manual use)
│   │   │   ├── user-entities.yaml               ← Static
│   │   │   ├── dynamic-plugins.yaml             ← Static
│   │   │   ├── rbac.yaml                        ← Static
│   │   │   ├── backstage-instance.yaml          ← Static
│   │   │   ├── demo-project-namespace.yaml      ← Static
│   │   │   ├── developer-hub-operator.yaml      ← Static
│   │   │   └── kustomization.yaml               ← Kustomize config
│   │   ├── overlays/production/
│   │   └── README.md                            ← Developer Hub docs
│   │
│   ├── TERRAFORM_INTEGRATION.md                 ← Terraform usage guide
│   └── DEPLOYMENT_SUMMARY.md                    ← This file
│
└── suresh-rosa-automation/
    ├── variables-features.tf                     ← Added deploy_keycloak & deploy_developerhub
    ├── argocd-operator-applications.tf           ← Added Keycloak & Developer Hub resources
    └── terraform.tfvars.example                  ← Added example variables
```

## 🎯 Key Features

### 1. Dynamic Configuration

✅ **No Hardcoded Domains**
- All URLs use `{{CLUSTER_DOMAIN}}` placeholders
- Terraform detects cluster domain automatically
- Templates processed during deployment

✅ **Auto-Generated Secrets**
- OIDC client secret
- Session secret
- ArgoCD service account token
- All secrets unique per deployment

✅ **Template Processing**
```bash
# Templates (in Git)
keycloak-client.yaml.template    → Contains {{CLUSTER_DOMAIN}}
auth-secret.yaml.template         → Contains {{OIDC_CLIENT_SECRET}}
app-config.yaml.template          → Contains {{CLUSTER_DOMAIN}}

# Processed (by Terraform)
keycloak-client.yaml             → Real cluster domain
auth-secret.yaml                 → Real secrets
app-config.yaml                  → Real URLs
```

### 2. Terraform Integration

✅ **New Variables**
```hcl
# In terraform.tfvars
deploy_keycloak     = true   # Deploy Keycloak
deploy_developerhub = true   # Deploy Developer Hub
```

✅ **Automatic Deployment**
```bash
terraform apply
```

This will:
1. Detect cluster domain
2. Generate secrets
3. Process templates
4. Create ArgoCD applications
5. Deploy via GitOps

✅ **Dependency Management**
```
OpenShift GitOps
      ↓
  Keycloak  ← Must complete first
      ↓
Developer Hub  ← Depends on Keycloak
```

### 3. Complete Feature Set

#### Keycloak Stack
- ✅ RHBK Operator
- ✅ PostgreSQL database
- ✅ Realm: `myrealm`
- ✅ Client: `myclient`
- ✅ Default user: `test@gmail.com`
- ✅ Dynamic redirect URIs

#### Developer Hub Stack
- ✅ RHDH Operator
- ✅ PostgreSQL database
- ✅ Keycloak authentication (OIDC)
- ✅ ArgoCD plugin (frontend + backend)
- ✅ Tekton plugin
- ✅ Kubernetes plugin (frontend + backend)
- ✅ AI Lab templates
- ✅ User catalog with email matching

## 🚀 Quick Start

### Option 1: Terraform Deployment (Recommended)

```bash
# 1. Navigate to Terraform directory
cd /Users/sureshgaikwad/terraform/Final_ROSA_Deployment/suresh-rosa-automation

# 2. Edit terraform.tfvars
cat >> terraform.tfvars <<EOF
deploy_openshift_gitops = true
deploy_keycloak         = true
deploy_developerhub     = true
EOF

# 3. Deploy
terraform init
terraform plan
terraform apply
```

**Wait:** ~10-15 minutes for complete deployment

### Option 2: Manual Deployment

```bash
# 1. Get cluster domain
CLUSTER_DOMAIN=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}')

# 2. Process templates manually
cd /Users/sureshgaikwad/terraform/Final_ROSA_Deployment/gitops-catalog

# Process Keycloak templates
cd operators/keycloak/base
OIDC_SECRET=$(openssl rand -base64 32)
sed "s|{{CLUSTER_DOMAIN}}|$CLUSTER_DOMAIN|g; s|{{OIDC_CLIENT_SECRET}}|$OIDC_SECRET|g" \
  keycloak-client.yaml.template > keycloak-client.yaml

# Process Developer Hub templates
cd ../../developer-hub/base
SESSION_SECRET=$(openssl rand -base64 32)
ARGOCD_TOKEN=$(oc create token openshift-gitops-argocd-server -n openshift-gitops --duration=87600h)

sed "s|{{CLUSTER_DOMAIN}}|$CLUSTER_DOMAIN|g; s|{{OIDC_CLIENT_SECRET}}|$OIDC_SECRET|g; \
     s|{{SESSION_SECRET}}|$SESSION_SECRET|g; s|{{ARGOCD_TOKEN}}|$ARGOCD_TOKEN|g" \
  auth-secret.yaml.template > auth-secret.yaml

sed "s|{{CLUSTER_DOMAIN}}|$CLUSTER_DOMAIN|g" \
  app-config.yaml.template > app-config.yaml

# 3. Deploy with Kustomize
oc apply -k /Users/sureshgaikwad/terraform/Final_ROSA_Deployment/gitops-catalog/operators/keycloak/base
oc apply -k /Users/sureshgaikwad/terraform/Final_ROSA_Deployment/gitops-catalog/operators/developer-hub/base
```

## 🔍 Verification

### Check ArgoCD Applications

```bash
oc get application -n openshift-gitops | grep -E "keycloak|developer-hub"
```

Expected output:
```
keycloak        Synced  Healthy
developer-hub   Synced  Healthy
```

### Check Deployments

```bash
# Keycloak
oc get pods -n rhbk
oc get keycloak -n rhbk

# Developer Hub
oc get pods -n demo-project
oc get backstage -n demo-project
```

### Get URLs

```bash
CLUSTER_DOMAIN=$(oc get ingress.config.openshift.io/cluster -o jsonpath='{.spec.domain}')

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 Application URLs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 Developer Hub:"
echo "   https://backstage-developer-hub-demo-project.$CLUSTER_DOMAIN"
echo ""
echo "🔐 Keycloak:"
echo "   https://sample-kc-service-rhbk.$CLUSTER_DOMAIN"
echo ""
echo "🚀 ArgoCD:"
ARGOCD_URL=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')
echo "   https://$ARGOCD_URL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Default User"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   Email: test@gmail.com"
echo "   Username: myuser"
echo ""
```

## 📋 What's Configured

### Keycloak Configuration

| Setting | Value |
|---------|-------|
| Namespace | `rhbk` |
| Realm | `myrealm` |
| Client ID | `myclient` |
| Client Type | Confidential (OIDC) |
| Redirect URIs | Dynamic (based on cluster domain) |
| Users | `myuser` (test@gmail.com) |
| Database | PostgreSQL (StatefulSet) |

### Developer Hub Configuration

| Setting | Value |
|---------|-------|
| Namespace | `demo-project` |
| Authentication | Keycloak OIDC |
| Sign-in Resolver | Email matching |
| Database | PostgreSQL (Local) |
| Plugins | ArgoCD, Tekton, Kubernetes |
| Catalog | Backstage examples + AI Lab templates |

### Installed Operators

| Operator | Namespace | Version |
|----------|-----------|---------|
| OpenShift GitOps | `openshift-gitops` | latest |
| OpenShift Pipelines | `openshift-operators` | latest |
| RHBK Operator | `rhbk` | latest |
| RHDH Operator | `demo-project` | latest |

## 📚 Documentation

| Document | Location | Purpose |
|----------|----------|---------|
| **TERRAFORM_INTEGRATION.md** | `gitops-catalog/operators/` | Complete Terraform guide |
| **Keycloak README.md** | `gitops-catalog/operators/keycloak/` | Keycloak configuration details |
| **Developer Hub README.md** | `gitops-catalog/operators/developer-hub/` | Developer Hub configuration details |
| **DEPLOYMENT_SUMMARY.md** | `gitops-catalog/operators/` | This file |

## 🛠️ Customization

### Change Keycloak Users

Edit: `gitops-catalog/operators/keycloak/base/keycloak-realm.yaml`

```yaml
users:
  - username: "newuser"
    email: "newuser@company.com"
    firstName: "New"
    lastName: "User"
    enabled: true
    emailVerified: true
    credentials:
      - type: "password"
        value: "SecurePassword123!"
        temporary: false
```

### Add Developer Hub Users

Edit: `gitops-catalog/operators/developer-hub/base/user-entities.yaml`

```yaml
---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: newuser
spec:
  profile:
    displayName: New User
    email: newuser@company.com  # Must match Keycloak!
  memberOf: []
```

### Change Catalog Templates

Edit: `gitops-catalog/operators/developer-hub/base/app-config.yaml.template`

```yaml
catalog:
  locations:
    - type: url
      target: https://github.com/your-org/templates/blob/main/catalog.yaml
      rules:
        - allow: [Template]
```

## 🔧 Troubleshooting

### Templates Not Processed

**Symptom:** Configuration shows `{{CLUSTER_DOMAIN}}`

**Solution:**
```bash
# Re-run Terraform
terraform apply -target=null_resource.create_keycloak_application
terraform apply -target=null_resource.create_developerhub_application
```

### Login Fails

**Symptom:** "Invalid client secret" or "Failed to sign-in"

**Solution:**
```bash
# Check secrets match
KC_SECRET=$(oc get keycloakrealmimport myrealm-client-import -n rhbk -o jsonpath='{.spec.realm.clients[0].secret}')
DH_SECRET=$(oc get secret developer-hub-auth-secrets -n demo-project -o jsonpath='{.data.AUTH_OIDC_CLIENT_SECRET}' | base64 -d)

if [ "$KC_SECRET" != "$DH_SECRET" ]; then
  echo "Secrets don't match! Updating..."
  oc patch secret developer-hub-auth-secrets -n demo-project \
    -p "{\"stringData\":{\"AUTH_OIDC_CLIENT_SECRET\":\"$KC_SECRET\"}}"
  oc rollout restart deployment/backstage-developer-hub -n demo-project
fi
```

### ArgoCD Plugin Not Working

**Symptom:** ArgoCD tab shows "unauthorized"

**Solution:**
```bash
# Generate new token
ARGOCD_TOKEN=$(oc create token openshift-gitops-argocd-server -n openshift-gitops --duration=87600h)

# Update secret
oc patch secret developer-hub-auth-secrets -n demo-project \
  -p "{\"stringData\":{\"ARGOCD_AUTH_TOKEN\":\"$ARGOCD_TOKEN\"}}"

# Restart
oc rollout restart deployment/backstage-developer-hub -n demo-project
```

## ⚠️ Production Considerations

Before deploying to production:

1. **Change Secrets**
   - Generate strong, unique secrets
   - Store in secrets manager (Vault, AWS Secrets Manager)

2. **External Databases**
   - Use managed PostgreSQL (RDS, Azure DB, Cloud SQL)
   - Update connection strings in configurations

3. **Valid TLS Certificates**
   - Remove self-signed certificate workarounds
   - Use cert-manager or corporate CA

4. **High Availability**
   - Increase replica counts
   - Configure pod anti-affinity
   - Set up proper resource limits

5. **Enable RBAC**
   - Configure proper permission policies
   - Use Keycloak groups for authorization

6. **Monitoring**
   - Enable Prometheus metrics
   - Configure alerts
   - Set up log aggregation

## 🎉 Success Criteria

Your deployment is successful when:

✅ ArgoCD applications show "Synced" and "Healthy"
✅ All pods are running in `rhbk` and `demo-project` namespaces
✅ You can access Keycloak admin console
✅ You can log into Developer Hub with test@gmail.com
✅ ArgoCD plugin shows applications
✅ Tekton plugin shows pipelines
✅ AI Lab templates are visible in catalog

## 📞 Support

For issues:
1. Check the troubleshooting sections in this document
2. Review the detailed READMEs in each operator directory
3. Check ArgoCD application status and logs
4. Review OpenShift events: `oc get events -n <namespace> --sort-by='.lastTimestamp'`

---

**🎯 Ready to Deploy!**

Set `deploy_keycloak = true` and `deploy_developerhub = true` in your `terraform.tfvars` and run `terraform apply`.

