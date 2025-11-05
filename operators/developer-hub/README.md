# Red Hat Developer Hub Configuration

This directory contains the complete GitOps configuration for deploying Red Hat Developer Hub with Keycloak authentication, ArgoCD, and Tekton plugins.

## Contents

### Base Configuration (`base/`)

- **demo-project-namespace.yaml** - Namespace for Developer Hub
- **developer-hub-operator.yaml** - RHDH Operator subscription
- **auth-secret.yaml** - Authentication secrets (OIDC, ArgoCD)
- **app-config.yaml** - Main application configuration
- **user-entities.yaml** - User catalog entities
- **dynamic-plugins.yaml** - ArgoCD and Tekton plugins
- **rbac.yaml** - Kubernetes RBAC permissions
- **backstage-instance.yaml** - Developer Hub instance

### Overlays

- **overlays/production/** - Production-specific configurations

## Features Configured

✅ **Keycloak Authentication (OIDC)**
- Realm: `myrealm`
- Client: `myclient`
- Email-based user resolution

✅ **AI Lab Templates**
- Imported from: https://github.com/redhat-ai-dev/ai-lab-template

✅ **ArgoCD Plugin**
- GitOps application management
- Sync status visualization

✅ **Tekton Plugin**
- CI/CD pipeline visualization
- Pipeline run monitoring

✅ **Kubernetes Plugin**
- Resource viewing
- Pod status monitoring

## Deployment

### Prerequisites

1. **Keycloak Deployed**
   - Deploy the `../keycloak/` configuration first
   - Get the Keycloak route URL
   - Get the OIDC client secret

2. **Operators Required**
   - OpenShift GitOps (ArgoCD)
   - OpenShift Pipelines (Tekton)
   - RHDH Operator

### Quick Deploy

```bash
# Update secrets first!
# Edit auth-secret.yaml with:
# - Keycloak client secret
# - ArgoCD URL and token

# Deploy base configuration
oc apply -k base/

# Or deploy production overlay
oc apply -k overlays/production/
```

### Deployment Order (via ArgoCD sync waves)

1. **Wave 0**: Namespace
2. **Wave 1**: Operator
3. **Wave 3**: Secrets, ConfigMaps, RBAC, Dynamic Plugins
4. **Wave 4**: Backstage instance

## Configuration Details

### Namespace
- **Name**: `demo-project`
- **Purpose**: Hosts Developer Hub and its dependencies

### Authentication
- **Provider**: OIDC (Keycloak)
- **Realm**: `myrealm`
- **Client ID**: `myclient`
- **Sign-in Resolver**: Email matching
- **Guest Access**: Disabled (production mode)

### Database
- **Type**: PostgreSQL
- **Mode**: Local (enableLocalDb: true)
- **For Production**: Use external PostgreSQL

### Plugins Enabled

| Plugin | Purpose |
|--------|---------|
| ArgoCD (Backend) | GitOps integration |
| ArgoCD (Frontend) | UI components |
| Tekton | CI/CD pipelines |
| Kubernetes (Backend) | K8s resource access |
| Kubernetes (Frontend) | K8s UI components |

### Catalog Locations

```yaml
locations:
  # Default examples
  - https://github.com/backstage/backstage/...
  
  # User entities (from ConfigMap)
  - file:///opt/app-root/src/user-entities.yaml
  
  # AI Lab Templates
  - https://github.com/redhat-ai-dev/ai-lab-template/blob/main/all.yaml
```

## URLs (After Deployment)

```bash
# Get Developer Hub URL
oc get route -n demo-project -o jsonpath='{.items[0].spec.host}'
```

Default URL pattern: `https://backstage-developer-hub-demo-project.apps.<cluster-domain>`

## Credentials

### Authentication Secrets

All sensitive data is in `auth-secret.yaml`:

```yaml
# OIDC (Keycloak)
AUTH_OIDC_CLIENT_ID: "myclient"
AUTH_OIDC_CLIENT_SECRET: "..." # From Keycloak

# Session
AUTH_SESSION_SECRET: "..." # Random generated

# ArgoCD
ARGOCD_URL: "https://..." # ArgoCD server URL
ARGOCD_AUTH_TOKEN: "..." # Service account token

# Node TLS (for self-signed certs)
NODE_TLS_REJECT_UNAUTHORIZED: "0" # Remove in production
```

### User Entities

Default user in `user-entities.yaml`:
- **Username**: `test`
- **Email**: `test@gmail.com`
- **Keycloak User**: Must have matching email

## Customization

### Update URLs

After deployment, update these URLs in `app-config.yaml`:

```yaml
app:
  baseUrl: https://<your-developer-hub-url>

backend:
  baseUrl: https://<your-developer-hub-url>
  cors:
    origin: https://<your-developer-hub-url>

auth:
  providers:
    oidc:
      production:
        metadataUrl: https://<keycloak-url>/realms/myrealm/.well-known/openid-configuration
```

### Add Users

Edit `user-entities.yaml`:

```yaml
---
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: newuser
spec:
  profile:
    displayName: New User
    email: newuser@example.com  # Must match Keycloak
  memberOf: []
```

### Add More Templates

Edit `app-config.yaml`, add to `catalog.locations`:

```yaml
- type: url
  target: https://github.com/your-org/templates/blob/main/catalog.yaml
  rules:
    - allow: [Template]
```

### Enable/Disable Plugins

Edit `dynamic-plugins.yaml`:

```yaml
plugins:
  - package: './dynamic-plugins/dist/plugin-name'
    disabled: false  # Change to true to disable
```

## Configuration Scripts

Helper scripts are available at `/tmp/`:

```bash
# Install ArgoCD and Tekton operators
/tmp/install-operators.sh

# Configure plugins
/tmp/configure-plugins.sh

# Complete setup
/tmp/run-complete-setup.sh
```

## Verification

### Check Operator
```bash
oc get csv -n demo-project
```

### Check Developer Hub
```bash
oc get backstage -n demo-project
oc get pods -n demo-project
```

### Check Route
```bash
oc get route -n demo-project
```

### Access Developer Hub
```bash
DEVHUB_URL=$(oc get route -n demo-project -o jsonpath='{.items[0].spec.host}')
echo "https://$DEVHUB_URL"
```

### Check Logs
```bash
oc logs -f deployment/backstage-developer-hub -n demo-project
```

## Troubleshooting

### Authentication Issues

```bash
# Check secret
oc get secret developer-hub-auth-secrets -n demo-project -o yaml

# Check OIDC connection
oc logs -f deployment/backstage-developer-hub -n demo-project | grep -i oidc

# Verify Keycloak is accessible
curl -k https://<keycloak-url>/realms/myrealm/.well-known/openid-configuration
```

### Plugin Not Loading

```bash
# Check dynamic plugins ConfigMap
oc get configmap dynamic-plugins-rhdh -n demo-project -o yaml

# Check if plugins are referenced in Backstage CR
oc get backstage developer-hub -n demo-project -o yaml | grep dynamicPlugins

# Restart Developer Hub
oc rollout restart deployment/backstage-developer-hub -n demo-project
```

### User Not Found After Login

```bash
# Check user entities
oc get configmap backstage-user-entities -n demo-project -o yaml

# Verify email matches
# User entity email MUST match Keycloak user email exactly
```

### Database Issues

```bash
# Check PostgreSQL pod
oc get pods -n demo-project | grep psql

# Check database logs
oc logs backstage-psql-developer-hub-0 -n demo-project

# Check connection
oc exec deployment/backstage-developer-hub -n demo-project -- \
  psql -h backstage-psql-developer-hub -U postgres -l
```

## Security Notes

⚠️ **Before Production:**

1. **Update All Secrets**
   ```bash
   # Generate new client secret
   openssl rand -base64 32
   
   # Generate new session secret
   openssl rand -base64 32
   
   # Update auth-secret.yaml with new values
   ```

2. **Use External Database**
   - Configure external PostgreSQL
   - Update `backstage-instance.yaml`:
     ```yaml
     database:
       enableLocalDb: false
       passwordSecret:
         name: postgres-secret
         key: password
     ```

3. **Remove Self-Signed Cert Workaround**
   - Get proper TLS certificates
   - Remove `NODE_TLS_REJECT_UNAUTHORIZED: "0"`
   - Remove `dangerouslyAllowInsecureHttpRequests: true`

4. **Enable RBAC**
   - Configure permission policies
   - Set up role-based access control
   - Use Keycloak groups for permissions

5. **Configure Proper Resource Limits**
   - Update `backstage-instance.yaml` with resource limits
   - Set appropriate replica count
   - Configure autoscaling

## Integration with Keycloak

This configuration expects Keycloak to be deployed from `../keycloak/`:

Required from Keycloak:
- Realm: `myrealm`
- Client ID: `myclient`
- Client Secret: Must match `AUTH_OIDC_CLIENT_SECRET`
- Users with verified emails

User email in Keycloak **MUST** match email in User entities.

## Integration with ArgoCD

Required ArgoCD configuration:
- OpenShift GitOps Operator installed
- ArgoCD instance in `openshift-gitops` namespace
- Service account token for API access

Get token:
```bash
oc create token openshift-gitops-argocd-server \
  -n openshift-gitops --duration=87600h
```

## Integration with Tekton

Required Tekton configuration:
- OpenShift Pipelines Operator installed
- RBAC permissions granted (via `rbac.yaml`)

Pipelines in `demo-project` namespace will be automatically discovered.

## Component Annotations

To link components to ArgoCD, Tekton, and Kubernetes, add annotations:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-app
  annotations:
    # ArgoCD
    argocd/app-name: my-app
    argocd/instance: main
    
    # Kubernetes
    backstage.io/kubernetes-id: my-app
    backstage.io/kubernetes-namespace: demo-project
    
    # Tekton
    janus-idp.io/tekton: my-app
spec:
  type: service
  lifecycle: production
  owner: team-a
```

## References

- [RHDH Documentation](https://access.redhat.com/documentation/en-us/red_hat_developer_hub)
- [Backstage Documentation](https://backstage.io/docs/)
- [ArgoCD Plugin](https://www.npmjs.com/package/@roadiehq/backstage-plugin-argo-cd)
- [Tekton Plugin](https://www.npmjs.com/package/@janus-idp/backstage-plugin-tekton)

---

**Part of the Developer Hub Stack GitOps Configuration**

