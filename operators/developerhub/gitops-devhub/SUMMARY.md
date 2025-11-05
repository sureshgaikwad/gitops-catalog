# GitOps Configuration Summary

## 🎉 Complete GitOps Setup Created!

This repository contains a complete, production-ready GitOps configuration for deploying Red Hat Developer Hub with Keycloak authentication on OpenShift.

## 📁 Directory Structure

```
gitops-devhub/
├── README.md                     # Complete documentation
├── QUICKSTART.md                 # 15-minute quick start guide
├── DEPLOYMENT_GUIDE.md           # Detailed deployment instructions
├── SUMMARY.md                    # This file
├── .gitignore                    # Git ignore patterns
│
├── base/                         # Base Kubernetes manifests
│   ├── namespaces/              # Namespace definitions
│   │   ├── rhbk-namespace.yaml
│   │   ├── demo-project-namespace.yaml
│   │   └── kustomization.yaml
│   │
│   ├── operators/               # Operator subscriptions
│   │   ├── rhbk-operator.yaml
│   │   ├── developer-hub-operator.yaml
│   │   └── kustomization.yaml
│   │
│   ├── keycloak/                # Keycloak configuration
│   │   ├── keycloak-instance.yaml      # Keycloak server + PostgreSQL
│   │   ├── keycloak-realm.yaml         # Realm with users
│   │   ├── keycloak-client.yaml        # OIDC client for Developer Hub
│   │   └── kustomization.yaml
│   │
│   └── developer-hub/           # Developer Hub configuration
│       ├── auth-secret.yaml             # OIDC credentials
│       ├── app-config.yaml              # Main configuration
│       ├── user-entities.yaml           # User catalog
│       ├── backstage-instance.yaml      # Developer Hub instance
│       └── kustomization.yaml
│
├── overlays/                    # Environment-specific configurations
│   └── production/
│       ├── kustomization.yaml
│       └── developer-hub-replicas-patch.yaml
│
├── argocd/                      # ArgoCD Application manifests
│   ├── app-of-apps.yaml                # Master application
│   ├── namespaces-app.yaml            # Namespaces app
│   ├── operators-app.yaml             # Operators app
│   ├── keycloak-app.yaml              # Keycloak app
│   └── developer-hub-app.yaml         # Developer Hub app
│
└── scripts/                     # Helper scripts
    ├── setup.sh                         # Initial setup script
    └── update-routes.sh                 # Update routes after deployment
```

## 🚀 What's Included

### Base Configurations

1. **Namespaces** (`base/namespaces/`)
   - `rhbk` - For Keycloak and its components
   - `demo-project` - For Developer Hub

2. **Operators** (`base/operators/`)
   - Red Hat Build of Keycloak Operator
   - Red Hat Developer Hub Operator
   - Automatic installation and updates

3. **Keycloak** (`base/keycloak/`)
   - Keycloak instance with PostgreSQL database
   - Realm: `myrealm` with sample user
   - OIDC Client: `myclient` for Developer Hub
   - Proper redirect URIs and scopes

4. **Developer Hub** (`base/developer-hub/`)
   - Complete OIDC authentication configuration
   - User entities catalog
   - PostgreSQL database (local)
   - Route with TLS enabled

### ArgoCD Applications

Deployment is managed through ArgoCD with sync waves:

- **Wave 0:** Namespaces
- **Wave 1:** Operators
- **Wave 2:** Keycloak instance and database
- **Wave 3:** Keycloak realm, client, and Developer Hub configuration
- **Wave 4:** Developer Hub instance

### Helper Scripts

- **`scripts/setup.sh`** - Automated initial setup
  - Installs OpenShift GitOps
  - Configures permissions
  - Generates secrets
  - Updates Git URLs

- **`scripts/update-routes.sh`** - Route updater
  - Gets routes from cluster
  - Updates all configuration files
  - Ready to commit

## 📝 Current Configuration

### Keycloak
- **Instance:** `sample-kc`
- **Realm:** `myrealm`
- **Client ID:** `myclient`
- **Client Secret:** `MTQLOQRT1pXkxLyXCyHzlRavSiofUZJ7` ⚠️  CHANGE THIS!
- **Sample User:** `myuser` / `test@gmail.com`
- **Password:** `changeme` ⚠️  CHANGE THIS!

### Developer Hub
- **Instance:** `developer-hub`
- **Authentication:** OIDC via Keycloak
- **Resolver:** Email matching
- **Database:** Local PostgreSQL
- **Replicas:** 1 (base), 2 (production overlay)
- **Users:** `test@gmail.com`

## ⚠️ Important: Before Deploying

### 1. Update Git Repository URL

In all files under `argocd/`:
```bash
sed -i 's|YOUR-ORG|your-actual-org|g' argocd/*.yaml
```

### 2. Generate New Secrets

```bash
# Client secret
openssl rand -base64 32

# Session secret
openssl rand -base64 32

# Update in:
# - base/keycloak/keycloak-client.yaml
# - base/developer-hub/auth-secret.yaml
```

### 3. Update User Information

Edit `base/keycloak/keycloak-realm.yaml`:
- Change username, email, password

Edit `base/developer-hub/user-entities.yaml`:
- Update email to match Keycloak user

### 4. Update Routes (After First Deployment)

```bash
./scripts/update-routes.sh
```

## 🎯 Quick Deployment

### For Impatient People (15 minutes)

```bash
# 1. Run setup
./scripts/setup.sh

# 2. Customize users
vi base/keycloak/keycloak-realm.yaml
vi base/developer-hub/user-entities.yaml

# 3. Commit
git add . && git commit -m "Initial config" && git push

# 4. Deploy
oc apply -f argocd/app-of-apps.yaml

# 5. Wait ~8 minutes, then update routes
./scripts/update-routes.sh
git add . && git commit -m "Update routes" && git push
```

See `QUICKSTART.md` for details.

### For Careful People

Follow the comprehensive guide in `DEPLOYMENT_GUIDE.md`

## 📚 Documentation

| File | Purpose |
|------|---------|
| `README.md` | Complete reference documentation |
| `QUICKSTART.md` | Fast 15-minute deployment |
| `DEPLOYMENT_GUIDE.md` | Step-by-step detailed guide |
| `SUMMARY.md` | This overview |

## 🔒 Security Considerations

### Secrets in Git

**Current approach:** Secrets are base64-encoded in YAML (NOT secure for production)

**Production recommendations:**
1. Use **Sealed Secrets** - Encrypt secrets for Git
2. Use **External Secrets Operator** - Store in Vault/AWS Secrets Manager
3. Use **SOPS** - Encrypt files with PGP/KMS
4. Never commit actual secrets to Git

### Production Checklist

- [ ] Change all default passwords
- [ ] Generate new client secrets
- [ ] Use proper TLS certificates (not self-signed)
- [ ] Enable RBAC in Developer Hub
- [ ] Use external PostgreSQL database
- [ ] Set up backup and disaster recovery
- [ ] Configure monitoring and alerting
- [ ] Implement proper secret management
- [ ] Set up resource limits
- [ ] Configure network policies

## 🛠 Customization

### Adding Users

Edit `base/developer-hub/user-entities.yaml`:
```yaml
---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: newuser
spec:
  profile:
    displayName: New User
    email: newuser@example.com
  memberOf: []
```

Commit and push - ArgoCD will sync automatically.

### Environment-Specific Configurations

Use overlays for different environments:

```bash
overlays/
├── development/
├── staging/
└── production/
```

Each can patch base configurations:
- Different replica counts
- Different resource limits
- Different database configurations
- Different URLs

### Enabling RBAC

Add to `base/developer-hub/app-config.yaml`:
```yaml
permission:
  enabled: true
  rbac:
    policies:
      - policy: ...
```

## 🔄 GitOps Workflow

1. **Make changes** to YAML files
2. **Commit and push** to Git
3. **ArgoCD automatically syncs** changes to cluster
4. **Verify** in ArgoCD UI or CLI

No manual `oc apply` needed after initial setup!

## 📊 Monitoring

### Check ArgoCD Applications

```bash
argocd app list
argocd app get developer-hub
```

### Check Resources

```bash
oc get all -n rhbk
oc get all -n demo-project
```

### Check Logs

```bash
oc logs -f deployment/backstage-developer-hub -n demo-project
oc logs -f deployment/keycloak -n rhbk
```

## 🆘 Support

### Logs

- **Keycloak:** `oc logs -f $(oc get pod -n rhbk -l app=keycloak -o name) -n rhbk`
- **Developer Hub:** `oc logs -f deployment/backstage-developer-hub -n demo-project`
- **ArgoCD:** Check ArgoCD UI for sync status

### Common Issues

1. **Sync fails:** Check ArgoCD app details for errors
2. **Pods CrashLoopBackOff:** Check logs and events
3. **Authentication fails:** Verify redirect URIs and secrets match
4. **User not found:** Ensure email matches between Keycloak and catalog

### Getting Help

- Red Hat Developer Hub: https://access.redhat.com/documentation/en-us/red_hat_developer_hub
- RHBK: https://access.redhat.com/documentation/en-us/red_hat_build_of_keycloak
- OpenShift GitOps: https://docs.openshift.com/gitops/

## 🎓 Next Steps

After successful deployment:

1. **Security**
   - Change default passwords
   - Implement proper secret management
   - Set up TLS certificates

2. **Configuration**
   - Add more users
   - Configure RBAC
   - Set up catalog locations

3. **Integration**
   - Connect to GitHub/GitLab
   - Configure CI/CD pipelines
   - Set up monitoring

4. **Advanced**
   - Create software templates
   - Configure additional plugins
   - Set up multi-environment deployments

## 📦 What You Get

A complete, working Developer Hub installation with:

✅ OIDC authentication via Keycloak
✅ User management
✅ GitOps-based deployment
✅ Automatic synchronization
✅ Version control for all configurations
✅ Easy rollback capabilities
✅ Environment-specific overlays
✅ Production-ready architecture
✅ Comprehensive documentation
✅ Helper scripts for common tasks

---

**Made with ❤️  for OpenShift + Developer Hub + Keycloak GitOps deployment**

For questions or issues, refer to the documentation files or Red Hat support.

