# Quick Start Guide

Get Developer Hub with Keycloak authentication running in 15 minutes!

## Prerequisites

- OpenShift cluster (ROSA or any OpenShift 4.12+)
- Cluster admin access
- `oc` CLI installed and logged in
- Git repository to host these files

## 5-Step Quick Deployment

### Step 1: Run Setup Script (3 minutes)

```bash
cd gitops-devhub
./scripts/setup.sh
```

This will:
- Install OpenShift GitOps Operator
- Grant necessary permissions
- Help you configure Git repository
- Generate secrets

### Step 2: Customize Users (2 minutes)

Edit user information:

```bash
vi base/keycloak/keycloak-realm.yaml
# Update user email and password

vi base/developer-hub/user-entities.yaml
# Update user email to match Keycloak
```

### Step 3: Commit to Git (1 minute)

```bash
git add .
git commit -m "Initial Developer Hub configuration"
git push origin main
```

### Step 4: Deploy (1 minute)

```bash
oc apply -f argocd/app-of-apps.yaml
```

### Step 5: Wait and Update Routes (8 minutes)

Wait for deployment (check ArgoCD UI or CLI):

```bash
# Watch ArgoCD sync
watch argocd app list

# Once deployed, update routes
./scripts/update-routes.sh

# Commit and push
git add .
git commit -m "Update routes"
git push
```

## Access Applications

```bash
# Get URLs
echo "Keycloak: https://$(oc get route -n rhbk -o jsonpath='{.items[0].spec.host}')"
echo "Developer Hub: https://$(oc get route -n demo-project -o jsonpath='{.items[0].spec.host}')"
echo "ArgoCD: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"
```

## Test Login

1. Open Developer Hub URL
2. Click "Sign In"
3. Login with Keycloak credentials:
   - Username: `myuser`
   - Password: `changeme` (or what you set)
4. Success! 🎉

## What Gets Deployed?

| Component | Namespace | Description |
|-----------|-----------|-------------|
| RHBK Operator | rhbk | Keycloak operator |
| Keycloak | rhbk | Identity provider |
| PostgreSQL | rhbk | Keycloak database |
| RHDH Operator | demo-project | Developer Hub operator |
| Developer Hub | demo-project | Main application |
| PostgreSQL | demo-project | Developer Hub database |

## Troubleshooting

### Deployment stuck?

```bash
# Check ArgoCD
argocd app list
argocd app get developer-hub

# Check pods
oc get pods -n rhbk
oc get pods -n demo-project

# Check logs
oc logs -f deployment/backstage-developer-hub -n demo-project
```

### Can't login?

1. Check user email matches in both Keycloak and Developer Hub
2. Verify redirect URIs in Keycloak client
3. Check Developer Hub logs for auth errors

### Need help?

See comprehensive guides:
- `README.md` - Full documentation
- `DEPLOYMENT_GUIDE.md` - Detailed deployment steps
- `base/keycloak/` - Keycloak configuration reference
- `base/developer-hub/` - Developer Hub configuration reference

## Next Steps

1. Change default passwords
2. Add more users
3. Configure RBAC
4. Set up proper TLS certificates
5. Configure catalog locations
6. Create software templates

## Clean Up

```bash
oc delete application -n openshift-gitops developer-hub-stack
# or
oc delete namespace rhbk demo-project
```

---

**Happy developing with Developer Hub! 🚀**

