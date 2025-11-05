# Developer Hub with Keycloak GitOps Configuration

This repository contains the complete GitOps configuration for deploying Red Hat Developer Hub with Red Hat Build of Keycloak (RHBK) authentication on OpenShift.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenShift Cluster (ROSA)                  │
│                                                              │
│  ┌────────────────────┐          ┌────────────────────┐    │
│  │  rhbk namespace    │          │  demo-project      │    │
│  │                    │          │                    │    │
│  │  ┌──────────────┐  │          │  ┌──────────────┐ │    │
│  │  │  Keycloak    │  │◄─────────┤  │ Developer    │ │    │
│  │  │  (RHBK)      │  │  OIDC    │  │ Hub          │ │    │
│  │  │              │  │  Auth    │  │              │ │    │
│  │  │  Realm:      │  │          │  │              │ │    │
│  │  │  - myrealm   │  │          │  └──────────────┘ │    │
│  │  │  Client:     │  │          │                    │    │
│  │  │  - myclient  │  │          │  ┌──────────────┐ │    │
│  │  └──────────────┘  │          │  │ PostgreSQL   │ │    │
│  │                    │          │  │              │ │    │
│  └────────────────────┘          │  └──────────────┘ │    │
│                                   │                    │    │
└───────────────────────────────────┴────────────────────┘    
```

## Directory Structure

```
gitops-devhub/
├── README.md                          # This file
├── base/                              # Base configurations
│   ├── namespaces/                    # Namespace definitions
│   │   ├── rhbk-namespace.yaml
│   │   ├── demo-project-namespace.yaml
│   │   └── kustomization.yaml
│   ├── operators/                     # Operator subscriptions
│   │   ├── rhbk-operator.yaml
│   │   ├── developer-hub-operator.yaml
│   │   └── kustomization.yaml
│   ├── keycloak/                      # Keycloak configuration
│   │   ├── keycloak-instance.yaml
│   │   ├── keycloak-realm.yaml
│   │   ├── keycloak-client.yaml
│   │   └── kustomization.yaml
│   └── developer-hub/                 # Developer Hub configuration
│       ├── auth-secret.yaml
│       ├── app-config.yaml
│       ├── user-entities.yaml
│       ├── backstage-instance.yaml
│       └── kustomization.yaml
├── overlays/                          # Environment-specific overlays
│   └── production/
│       ├── namespaces/
│       ├── operators/
│       ├── keycloak/
│       ├── developer-hub/
│       └── kustomization.yaml
└── argocd/                            # ArgoCD Application manifests
    ├── app-of-apps.yaml
    ├── namespaces-app.yaml
    ├── operators-app.yaml
    ├── keycloak-app.yaml
    └── developer-hub-app.yaml
```

## Prerequisites

1. **OpenShift Cluster** - ROSA or any OpenShift 4.12+
2. **OpenShift GitOps Operator** - Installed in the cluster
3. **Cluster Admin Access** - Required for operator installation
4. **Git Repository** - To host these configurations

## Deployment Order

The applications are deployed in the following order using ArgoCD sync waves:

1. **Wave 0:** Namespaces (`rhbk`, `demo-project`)
2. **Wave 1:** Operators (RHBK Operator, Developer Hub Operator)
3. **Wave 2:** Keycloak Instance, Realm, and Client
4. **Wave 3:** Developer Hub Instance with Auth Configuration

## Quick Start

### 1. Fork/Clone this Repository

```bash
git clone <your-repo-url>
cd gitops-devhub
```

### 2. Customize Configurations

Edit the following files with your specific values:

- `base/keycloak/keycloak-client.yaml` - Update redirect URIs with your routes
- `base/developer-hub/auth-secret.yaml` - Update client secret
- `base/developer-hub/app-config.yaml` - Update URLs with your routes
- `base/developer-hub/user-entities.yaml` - Add your users

### 3. Deploy using OpenShift GitOps

#### Option A: App of Apps Pattern (Recommended)

```bash
oc apply -f argocd/app-of-apps.yaml
```

This will create all ArgoCD applications in the correct order.

#### Option B: Individual Applications

```bash
# Deploy in order
oc apply -f argocd/namespaces-app.yaml
oc apply -f argocd/operators-app.yaml
oc apply -f argocd/keycloak-app.yaml
oc apply -f argocd/developer-hub-app.yaml
```

#### Option C: Using Kustomize Directly (Without ArgoCD)

```bash
# Deploy base configurations
oc apply -k base/namespaces/
oc apply -k base/operators/

# Wait for operators to be ready
sleep 60

# Deploy Keycloak
oc apply -k base/keycloak/

# Wait for Keycloak to be ready
sleep 120

# Deploy Developer Hub
oc apply -k base/developer-hub/
```

### 4. Verify Deployment

```bash
# Check namespaces
oc get namespaces rhbk demo-project

# Check operators
oc get csv -n rhbk
oc get csv -n demo-project

# Check Keycloak
oc get keycloak -n rhbk
oc get route -n rhbk

# Check Developer Hub
oc get backstage -n demo-project
oc get route -n demo-project

# Check all pods
oc get pods -n rhbk
oc get pods -n demo-project
```

### 5. Access Applications

```bash
# Get URLs
KEYCLOAK_URL=$(oc get route -n rhbk -o jsonpath='{.items[0].spec.host}')
DEVHUB_URL=$(oc get route -n demo-project -o jsonpath='{.items[0].spec.host}')

echo "Keycloak: https://$KEYCLOAK_URL"
echo "Developer Hub: https://$DEVHUB_URL"
```

## Configuration Details

### Keycloak Configuration

- **Realm:** `myrealm`
- **Client ID:** `myclient`
- **Client Type:** Confidential
- **Authentication Flow:** Standard Flow (Authorization Code)
- **Redirect URIs:** Configured for Developer Hub OIDC handler

### Developer Hub Configuration

- **Authentication:** OIDC via Keycloak
- **Database:** PostgreSQL (local)
- **Sign-in Resolver:** Email matching
- **User Entities:** File-based catalog
- **Permissions:** Default (all users have full access)

### Current Users

- **Username:** test
- **Email:** test@gmail.com
- **Role:** Admin (full permissions)

## Customization

### Adding More Users

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

### Changing Authentication Settings

Edit `base/developer-hub/app-config.yaml` to modify:
- OIDC settings
- Sign-in resolvers
- Session configuration

### Environment-Specific Overrides

Use overlays for different environments:

```bash
overlays/
├── development/
├── staging/
└── production/
```

Each overlay can patch base configurations for that environment.

## Troubleshooting

### Keycloak Not Starting

```bash
# Check operator
oc get csv -n rhbk

# Check Keycloak logs
oc logs -f $(oc get pod -n rhbk -l app=keycloak -o name) -n rhbk

# Check events
oc get events -n rhbk --sort-by='.lastTimestamp'
```

### Developer Hub Not Starting

```bash
# Check operator
oc get csv -n demo-project

# Check Backstage CR
oc get backstage -n demo-project -o yaml

# Check logs
oc logs -f deployment/backstage-developer-hub -n demo-project

# Check pods
oc get pods -n demo-project
oc describe pod <pod-name> -n demo-project
```

### Authentication Issues

1. **Verify Keycloak client redirect URIs**
2. **Check client secret matches in both systems**
3. **Verify user email in Keycloak matches User entity**
4. **Check Developer Hub logs for OIDC errors**

## Security Considerations

### Secrets Management

**Current approach:** Secrets are stored in YAML files (base64 encoded)

**Production recommendations:**
- Use **Sealed Secrets** or **External Secrets Operator**
- Store secrets in **HashiCorp Vault** or **AWS Secrets Manager**
- Never commit actual secrets to Git

### Example with Sealed Secrets:

```bash
# Create sealed secret
kubeseal --format=yaml < auth-secret.yaml > auth-secret-sealed.yaml

# Commit sealed secret to Git
git add auth-secret-sealed.yaml
git commit -m "Add sealed auth secret"
```

### RBAC and Permissions

Current setup has permissions disabled. For production:

1. Enable RBAC in Developer Hub
2. Configure permission policies
3. Use Keycloak groups for role mapping

## Maintenance

### Updating Keycloak

```bash
# Update operator subscription
oc patch subscription rhbk-operator -n rhbk --type=merge -p '{"spec":{"channel":"stable"}}'
```

### Updating Developer Hub

```bash
# Update operator subscription
oc patch subscription rhdh -n demo-project --type=merge -p '{"spec":{"channel":"stable"}}'
```

### Syncing with ArgoCD

```bash
# Sync all applications
argocd app sync -l app.kubernetes.io/part-of=developer-hub-stack

# Sync specific app
argocd app sync developer-hub
```

## Backup and Disaster Recovery

### Backup Keycloak

```bash
# Export realm configuration
oc exec -n rhbk $(oc get pod -n rhbk -l app=keycloak -o name) -- \
  /opt/keycloak/bin/kc.sh export --dir /tmp/export --realm myrealm

# Copy export
oc cp rhbk/$(oc get pod -n rhbk -l app=keycloak -o name | cut -d'/' -f2):/tmp/export ./keycloak-backup/
```

### Backup Developer Hub Catalog

```bash
# Backup PostgreSQL database
oc exec -n demo-project backstage-psql-developer-hub-0 -- \
  pg_dump -U postgres backstage > developer-hub-backup.sql
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Test locally with `oc apply -k`
4. Submit a pull request

## Support

For issues and questions:
- **Keycloak:** [RHBK Documentation](https://access.redhat.com/documentation/en-us/red_hat_build_of_keycloak)
- **Developer Hub:** [RHDH Documentation](https://access.redhat.com/documentation/en-us/red_hat_developer_hub)
- **OpenShift GitOps:** [GitOps Documentation](https://docs.openshift.com/gitops/)

## License

This configuration is provided as-is for reference and can be freely modified for your needs.

