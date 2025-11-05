## Complete Deployment Guide

This guide walks you through deploying the Developer Hub with Keycloak authentication using OpenShift GitOps.

## Prerequisites

### 1. Install OpenShift GitOps Operator

```bash
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
```

Wait for the operator to be ready:

```bash
oc get csv -n openshift-operators | grep gitops
```

### 2. Grant ArgoCD Cluster Admin (Required for Operator Installation)

```bash
oc adm policy add-cluster-role-to-user cluster-admin \
  system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller
```

### 3. Fork/Clone This Repository

```bash
git clone https://github.com/YOUR-ORG/gitops-devhub.git
cd gitops-devhub
```

## Configuration Steps

### Step 1: Update Repository URLs

Update all ArgoCD application manifests with your Git repository URL:

```bash
# Update all application manifests
sed -i 's|https://github.com/YOUR-ORG/gitops-devhub.git|https://github.com/YOUR-ACTUAL-ORG/gitops-devhub.git|g' argocd/*.yaml
```

### Step 2: Update Routes and URLs

After deploying, you'll get actual routes. Update these files:

**Files to update:**
- `base/keycloak/keycloak-client.yaml` - Update all redirect URIs
- `base/developer-hub/app-config.yaml` - Update baseUrl and OIDC metadataUrl

**Get your routes:**
```bash
# After initial deployment
KEYCLOAK_ROUTE=$(oc get route -n rhbk -o jsonpath='{.items[0].spec.host}')
DEVHUB_ROUTE=$(oc get route -n demo-project -o jsonpath='{.items[0].spec.host}')

echo "Keycloak: https://$KEYCLOAK_ROUTE"
echo "Developer Hub: https://$DEVHUB_ROUTE"
```

**Update the files:**
```bash
# Update Keycloak client
sed -i "s|backstage-developer-hub-demo-project.apps.rosa.sgaikwad.a98d.p3.openshiftapps.com|$DEVHUB_ROUTE|g" base/keycloak/keycloak-client.yaml

# Update Developer Hub config
sed -i "s|backstage-developer-hub-demo-project.apps.rosa.sgaikwad.a98d.p3.openshiftapps.com|$DEVHUB_ROUTE|g" base/developer-hub/app-config.yaml
sed -i "s|sample-kc-service-rhbk.apps.rosa.sgaikwad.a98d.p3.openshiftapps.com|$KEYCLOAK_ROUTE|g" base/developer-hub/app-config.yaml
```

### Step 3: Update Secrets (IMPORTANT!)

**Keycloak Client Secret:**
```bash
# Generate a new client secret
NEW_CLIENT_SECRET=$(openssl rand -base64 32)

# Update both files
sed -i "s|MTQLOQRT1pXkxLyXCyHzlRavSiofUZJ7|$NEW_CLIENT_SECRET|g" base/keycloak/keycloak-client.yaml
sed -i "s|MTQLOQRT1pXkxLyXCyHzlRavSiofUZJ7|$NEW_CLIENT_SECRET|g" base/developer-hub/auth-secret.yaml
```

**Session Secret:**
```bash
# Generate a new session secret
NEW_SESSION_SECRET=$(openssl rand -base64 32)

# Update auth secret
sed -i "s|U1nyHYCTIcm0LbPSBUDBiRvv8I8emzA2tSSStz2ydFI=|$NEW_SESSION_SECRET|g" base/developer-hub/auth-secret.yaml
```

### Step 4: Update Users

Edit `base/developer-hub/user-entities.yaml` and add your users with their Keycloak emails.

Also update `base/keycloak/keycloak-realm.yaml` with your actual users.

### Step 5: Commit and Push

```bash
git add .
git commit -m "Configure Developer Hub with Keycloak"
git push origin main
```

## Deployment

### Option A: App of Apps (Recommended)

Deploy everything with a single command:

```bash
oc apply -f argocd/app-of-apps.yaml
```

This will create all ArgoCD applications in the correct order.

### Option B: Manual Step-by-Step

```bash
# Step 1: Namespaces
oc apply -f argocd/namespaces-app.yaml

# Wait for sync
argocd app wait developer-hub-namespaces

# Step 2: Operators
oc apply -f argocd/operators-app.yaml

# Wait for operators to be installed (takes 3-5 minutes)
argocd app wait developer-hub-operators
oc get csv -n rhbk
oc get csv -n demo-project

# Step 3: Keycloak
oc apply -f argocd/keycloak-app.yaml

# Wait for Keycloak to be ready (takes 5-10 minutes)
argocd app wait developer-hub-keycloak
oc get keycloak -n rhbk
oc wait --for=condition=Ready keycloak/sample-kc -n rhbk --timeout=600s

# Step 4: Developer Hub
oc apply -f argocd/developer-hub-app.yaml

# Wait for Developer Hub to be ready (takes 3-5 minutes)
argocd app wait developer-hub
oc get backstage -n demo-project
```

## Verification

### 1. Check ArgoCD Applications

```bash
# List all applications
argocd app list

# Check sync status
argocd app get developer-hub-stack
argocd app get developer-hub-namespaces
argocd app get developer-hub-operators
argocd app get developer-hub-keycloak
argocd app get developer-hub
```

### 2. Check Resources

```bash
# Namespaces
oc get namespaces rhbk demo-project

# Operators
oc get csv -n rhbk
oc get csv -n demo-project

# Keycloak
oc get keycloak -n rhbk
oc get keycloakrealmimport -n rhbk
oc get pods -n rhbk
oc get route -n rhbk

# Developer Hub
oc get backstage -n demo-project
oc get pods -n demo-project
oc get route -n demo-project
```

### 3. Check Application Health

```bash
# Check all pods
oc get pods -n rhbk
oc get pods -n demo-project

# Check logs
oc logs -f deployment/backstage-developer-hub -n demo-project
oc logs -f $(oc get pod -n rhbk -l app=keycloak -o name) -n rhbk
```

### 4. Access Applications

```bash
# Get URLs
echo "Keycloak Admin: https://$(oc get route -n rhbk -o jsonpath='{.items[0].spec.host}')"
echo "Developer Hub: https://$(oc get route -n demo-project -o jsonpath='{.items[0].spec.host}')"

# Or use ArgoCD UI
echo "ArgoCD: https://$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}')"
```

## Post-Deployment Configuration

### 1. Verify Keycloak Client

Login to Keycloak and verify the client `myclient` in realm `myrealm`:
- Check redirect URIs match your Developer Hub route
- Verify client secret (optional - it should be set via GitOps)
- Test user login

### 2. Test Developer Hub Authentication

1. Navigate to Developer Hub URL
2. Click "Sign In"
3. You should be redirected to Keycloak
4. Login with user `myuser` (password: `changeme`)
5. You should be redirected back to Developer Hub

### 3. Update User Password

**In Keycloak UI:**
1. Go to Realm `myrealm` → Users → `myuser`
2. Go to Credentials tab
3. Set a new password
4. Uncheck "Temporary"

**Or via CLI:**
```bash
oc exec -n rhbk $(oc get pod -n rhbk -l app=keycloak -o name | head -1) -- \
  /opt/keycloak/bin/kcadm.sh update users/<user-id> \
  -r myrealm -s enabled=true --set credentials='[{"type":"password","value":"newpassword","temporary":false}]'
```

## Updating the Stack

### Update Keycloak Configuration

```bash
# Edit files
vi base/keycloak/keycloak-realm.yaml
vi base/keycloak/keycloak-client.yaml

# Commit and push
git add base/keycloak/
git commit -m "Update Keycloak configuration"
git push

# ArgoCD will automatically sync
# Or manually sync:
argocd app sync developer-hub-keycloak
```

### Update Developer Hub Configuration

```bash
# Edit files
vi base/developer-hub/app-config.yaml
vi base/developer-hub/user-entities.yaml

# Commit and push
git add base/developer-hub/
git commit -m "Update Developer Hub configuration"
git push

# ArgoCD will automatically sync
argocd app sync developer-hub
```

### Add New Users

```bash
# Edit user entities
vi base/developer-hub/user-entities.yaml

# Add new user:
cat <<EOF >> base/developer-hub/user-entities.yaml
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
EOF

# Commit and push
git add base/developer-hub/user-entities.yaml
git commit -m "Add new user"
git push
```

## Troubleshooting

### ArgoCD Shows "OutOfSync"

```bash
# Check the diff
argocd app diff developer-hub

# Force sync
argocd app sync developer-hub --force

# Refresh the app
argocd app get developer-hub --refresh
```

### Operator Not Installing

```bash
# Check operator pod
oc get pods -n openshift-operators | grep rhbk
oc get pods -n openshift-operators | grep rhdh

# Check subscription
oc get subscription -n rhbk
oc get subscription -n demo-project

# Check install plan
oc get installplan -n rhbk
oc get installplan -n demo-project
```

### Keycloak Not Starting

```bash
# Check Keycloak CR status
oc get keycloak sample-kc -n rhbk -o yaml

# Check pods
oc get pods -n rhbk

# Check logs
oc logs -f $(oc get pod -n rhbk -l app=keycloak -o name) -n rhbk

# Check events
oc get events -n rhbk --sort-by='.lastTimestamp'
```

### Developer Hub Not Starting

```bash
# Check Backstage CR status
oc get backstage developer-hub -n demo-project -o yaml

# Check pods
oc get pods -n demo-project

# Check logs
oc logs -f deployment/backstage-developer-hub -n demo-project

# Check events
oc get events -n demo-project --sort-by='.lastTimestamp'
```

## Cleanup

To remove everything:

```bash
# Delete all ArgoCD applications
oc delete application -n openshift-gitops developer-hub-stack
oc delete application -n openshift-gitops developer-hub
oc delete application -n openshift-gitops developer-hub-keycloak
oc delete application -n openshift-gitops developer-hub-operators
oc delete application -n openshift-gitops developer-hub-namespaces

# Or delete resources directly
oc delete namespace demo-project
oc delete namespace rhbk
```

## Best Practices

1. **Secrets Management**: Use Sealed Secrets or External Secrets Operator for production
2. **Branching Strategy**: Use separate branches for dev/staging/prod
3. **Review Process**: Require PR approvals for changes
4. **Backup**: Regular backup of Keycloak realm and Developer Hub database
5. **Monitoring**: Set up monitoring and alerting for both applications
6. **Updates**: Regular updates of operators and applications

## Next Steps

1. Enable RBAC in Developer Hub
2. Configure external PostgreSQL for production
3. Set up proper TLS certificates
4. Configure additional authentication providers
5. Set up catalog locations (GitHub, GitLab, etc.)
6. Create software templates
7. Configure additional plugins

