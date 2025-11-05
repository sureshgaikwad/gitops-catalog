# Architecture Overview

## Deployment Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        Terraform Apply                          │
│                     (terraform apply)                           │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   1. Cluster Detection                          │
│  • Get cluster domain from OpenShift                            │
│  • Generate secrets (OIDC, Session, ArgoCD)                     │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   2. Process Templates                          │
│                                                                 │
│  keycloak-client.yaml.template                                  │
│    {{CLUSTER_DOMAIN}} → apps.rosa.example.com                  │
│    {{OIDC_CLIENT_SECRET}} → abc123...                          │
│                                                                 │
│  auth-secret.yaml.template                                      │
│    {{CLUSTER_DOMAIN}} → apps.rosa.example.com                  │
│    {{OIDC_CLIENT_SECRET}} → abc123...                          │
│    {{SESSION_SECRET}} → xyz789...                              │
│    {{ARGOCD_TOKEN}} → eyJhbGci...                              │
│                                                                 │
│  app-config.yaml.template                                       │
│    {{CLUSTER_DOMAIN}} → apps.rosa.example.com                  │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   3. Create ArgoCD Apps                         │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ArgoCD Application: keycloak                             │  │
│  │   source: gitops-catalog/operators/keycloak/base         │  │
│  │   destination: namespace rhbk                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ ArgoCD Application: developer-hub                        │  │
│  │   source: gitops-catalog/operators/developer-hub/base    │  │
│  │   destination: namespace demo-project                    │  │
│  │   depends_on: keycloak                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│               4. ArgoCD Syncs Resources                         │
│                                                                 │
│  Wave 0: Namespaces                                             │
│    • rhbk namespace                                             │
│    • demo-project namespace                                     │
│                                                                 │
│  Wave 1: Operators                                              │
│    • RHBK Operator subscription                                 │
│    • RHDH Operator subscription                                 │
│    • OpenShift Pipelines subscription                           │
│                                                                 │
│  Wave 2: Databases & Keycloak                                   │
│    • PostgreSQL StatefulSet (Keycloak)                          │
│    • Keycloak instance                                          │
│                                                                 │
│  Wave 3: Configuration                                          │
│    • Keycloak realm (myrealm)                                   │
│    • Keycloak client (myclient)                                 │
│    • Developer Hub secrets                                      │
│    • Developer Hub ConfigMaps                                   │
│    • RBAC permissions                                           │
│                                                                 │
│  Wave 4: Applications                                           │
│    • PostgreSQL (Developer Hub)                                 │
│    • Developer Hub instance                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      ROSA Cluster                               │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ OpenShift GitOps (openshift-gitops namespace)            │  │
│  │                                                          │  │
│  │  ┌─────────────────────────────────────────────────┐    │  │
│  │  │ ArgoCD Server                                   │    │  │
│  │  │  • Manages applications                         │    │  │
│  │  │  • Provides web UI                              │    │  │
│  │  │  • API for Developer Hub plugin                 │    │  │
│  │  └─────────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Keycloak (rhbk namespace)                                │  │
│  │                                                          │  │
│  │  ┌─────────────────┐     ┌──────────────────────┐       │  │
│  │  │ PostgreSQL      │────▶│ Keycloak Instance    │       │  │
│  │  │ StatefulSet     │     │  • Realm: myrealm    │       │  │
│  │  │  • Storage: 1Gi │     │  • Client: myclient  │       │  │
│  │  └─────────────────┘     │  • OIDC Provider     │       │  │
│  │                          └──────────┬───────────┘       │  │
│  │                                     │                    │  │
│  │                          ┌──────────▼───────────┐       │  │
│  │                          │ Route (HTTPS)        │       │  │
│  │                          │ sample-kc-service-   │       │  │
│  │                          │ rhbk.apps.<domain>   │       │  │
│  │                          └──────────────────────┘       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                     │                           │
│                                     │ OIDC Auth                 │
│                                     ▼                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Developer Hub (demo-project namespace)                   │  │
│  │                                                          │  │
│  │  ┌─────────────────┐     ┌──────────────────────┐       │  │
│  │  │ PostgreSQL      │────▶│ Developer Hub        │       │  │
│  │  │ (Local)         │     │  • Backstage         │       │  │
│  │  │  • Managed by   │     │  • OIDC Auth         │       │  │
│  │  │    RHDH Operator│     │  • Catalog           │       │  │
│  │  └─────────────────┘     └──────────┬───────────┘       │  │
│  │                                     │                    │  │
│  │                          ┌──────────▼───────────┐       │  │
│  │                          │ Route (HTTPS)        │       │  │
│  │                          │ backstage-           │       │  │
│  │                          │ developer-hub-       │       │  │
│  │                          │ demo-project.        │       │  │
│  │                          │ apps.<domain>        │       │  │
│  │                          └──────────────────────┘       │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │ Plugins                                            │ │  │
│  │  │  • ArgoCD (frontend + backend)                     │ │  │
│  │  │  • Tekton                                          │ │  │
│  │  │  • Kubernetes (frontend + backend)                 │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  │           │              │                 │             │  │
│  │           ▼              ▼                 ▼             │  │
│  │     ┌─────────┐   ┌─────────────┐  ┌─────────────┐     │  │
│  │     │ ArgoCD  │   │ Tekton CRs  │  │ Kubernetes  │     │  │
│  │     │ API     │   │ (Pipelines) │  │ API         │     │  │
│  │     └─────────┘   └─────────────┘  └─────────────┘     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ OpenShift Pipelines (cluster-wide)                       │  │
│  │  • Tekton operator                                       │  │
│  │  • Pipeline resources visible to Developer Hub          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## User Authentication Flow

```
┌────────────┐
│   User     │
└─────┬──────┘
      │ 1. Access Developer Hub
      ▼
┌─────────────────────────────────────────┐
│ Developer Hub Route                     │
│ https://backstage-developer-hub-        │
│ demo-project.apps.<domain>              │
└─────┬───────────────────────────────────┘
      │ 2. Redirect to OIDC provider
      ▼
┌─────────────────────────────────────────┐
│ Keycloak                                │
│ https://sample-kc-service-rhbk.         │
│ apps.<domain>/realms/myrealm            │
└─────┬───────────────────────────────────┘
      │ 3. User enters credentials
      │    (test@gmail.com / password)
      ▼
┌─────────────────────────────────────────┐
│ Keycloak validates credentials          │
│  • Check username/email                 │
│  • Verify password                      │
│  • Generate OIDC tokens                 │
└─────┬───────────────────────────────────┘
      │ 4. Return OIDC tokens
      │    (ID token, Access token)
      ▼
┌─────────────────────────────────────────┐
│ Developer Hub                           │
│  • Receives OIDC tokens                 │
│  • Validates tokens                     │
│  • Resolves user via email              │
│    (emailMatchingUserEntityProfileEmail)│
└─────┬───────────────────────────────────┘
      │ 5. Match user entity
      ▼
┌─────────────────────────────────────────┐
│ User Catalog (user-entities.yaml)       │
│                                         │
│ apiVersion: backstage.io/v1alpha1       │
│ kind: User                              │
│ metadata:                               │
│   name: test                            │
│ spec:                                   │
│   profile:                              │
│     email: test@gmail.com ◄─── MATCH!  │
└─────┬───────────────────────────────────┘
      │ 6. User logged in
      ▼
┌─────────────────────────────────────────┐
│ Developer Hub Home Page                 │
│  • Catalog visible                      │
│  • Templates available                  │
│  • ArgoCD tab shows apps                │
│  • Tekton tab shows pipelines           │
└─────────────────────────────────────────┘
```

## Data Flow

```
┌───────────────────────────────────────────────────────────────┐
│                     Configuration Sources                      │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Git Repository (gitops-catalog)                              │
│    │                                                          │
│    ├─ operators/keycloak/base/                                │
│    │    ├─ keycloak-instance.yaml                             │
│    │    ├─ keycloak-realm.yaml                                │
│    │    └─ keycloak-client.yaml (generated from template)     │
│    │                                                          │
│    └─ operators/developer-hub/base/                           │
│         ├─ auth-secret.yaml (generated from template)         │
│         ├─ app-config.yaml (generated from template)          │
│         ├─ user-entities.yaml                                 │
│         ├─ dynamic-plugins.yaml                               │
│         └─ backstage-instance.yaml                            │
│                                                               │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     │ ArgoCD pulls
                     ▼
┌───────────────────────────────────────────────────────────────┐
│                     ArgoCD Applications                        │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Application: keycloak                                        │
│    source: gitops-catalog/operators/keycloak/base             │
│    syncPolicy: automated                                      │
│                                                               │
│  Application: developer-hub                                   │
│    source: gitops-catalog/operators/developer-hub/base        │
│    syncPolicy: automated                                      │
│    depends_on: keycloak                                       │
│                                                               │
└────────────────────┬──────────────────────────────────────────┘
                     │
                     │ Applies to
                     ▼
┌───────────────────────────────────────────────────────────────┐
│                    OpenShift Cluster                          │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Namespace: rhbk                                              │
│    • Keycloak Operator manages Keycloak CR                    │
│    • PostgreSQL stores Keycloak data                          │
│    • Keycloak serves OIDC                                     │
│                                                               │
│  Namespace: demo-project                                      │
│    • RHDH Operator manages Backstage CR                       │
│    • PostgreSQL stores Developer Hub data                     │
│    • Developer Hub serves web UI                              │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Network Flow

```
Internet
   │
   ▼
┌─────────────────────────────────────────┐
│ OpenShift Router                        │
│  • TLS termination                      │
│  • Route-based routing                  │
└─────┬───────────────────────┬───────────┘
      │                       │
      │                       └──────────────┐
      ▼                                      ▼
┌──────────────────────┐          ┌──────────────────────┐
│ Keycloak Route       │          │ Developer Hub Route  │
│ sample-kc-service-   │          │ backstage-           │
│ rhbk.apps.<domain>   │          │ developer-hub-       │
│                      │          │ demo-project.        │
│                      │          │ apps.<domain>        │
└─────┬────────────────┘          └─────┬────────────────┘
      │                                 │
      ▼                                 ▼
┌──────────────────────┐          ┌──────────────────────┐
│ Keycloak Service     │          │ Developer Hub Service│
│ Port: 8443           │◄─────────│ OIDC Client          │
│                      │   Auth   │                      │
└─────┬────────────────┘          └─────┬────────────────┘
      │                                 │
      ▼                                 │
┌──────────────────────┐                │
│ PostgreSQL Service   │                │
│ Port: 5432           │                │
│ (Keycloak DB)        │                │
└──────────────────────┘                │
                                        ▼
                            ┌──────────────────────┐
                            │ PostgreSQL Service   │
                            │ Port: 5432           │
                            │ (Developer Hub DB)   │
                            └──────────────────────┘

Developer Hub also connects to:
  • ArgoCD API (openshift-gitops namespace)
  • Kubernetes API (for Kubernetes plugin)
  • Tekton API (for Tekton plugin)
```

## Storage Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Persistent Storage                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Keycloak Namespace (rhbk)                                  │
│  ┌────────────────────────────────────────────────────┐    │
│  │ PostgreSQL StatefulSet                             │    │
│  │   └─ PersistentVolumeClaim: 1Gi                    │    │
│  │      └─ Data: Keycloak configuration, users, etc.  │    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
│  Developer Hub Namespace (demo-project)                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │ PostgreSQL Deployment (Managed by RHDH Operator)   │    │
│  │   └─ PersistentVolumeClaim: Auto-provisioned       │    │
│  │      └─ Data: Catalog entities, user sessions, etc.│    │
│  └────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Security Model

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Network Security                                        │
│     ├─ TLS encryption (HTTPS routes)                        │
│     ├─ OpenShift network policies                           │
│     └─ Service-to-service encryption                        │
│                                                             │
│  2. Authentication                                          │
│     ├─ Keycloak OIDC                                        │
│     ├─ No guest access (production mode)                    │
│     └─ Token-based authentication                           │
│                                                             │
│  3. Authorization                                           │
│     ├─ Keycloak roles and groups                            │
│     ├─ Developer Hub RBAC (optional)                        │
│     └─ OpenShift RBAC                                       │
│                                                             │
│  4. Secrets Management                                      │
│     ├─ OpenShift Secrets                                    │
│     │  ├─ OIDC client secret                                │
│     │  ├─ Session secret                                    │
│     │  ├─ ArgoCD token                                      │
│     │  └─ Database credentials                              │
│     └─ Encrypted at rest (etcd encryption)                  │
│                                                             │
│  5. Service Accounts                                        │
│     ├─ Developer Hub service account                        │
│     │  └─ RBAC for Kubernetes API access                    │
│     └─ ArgoCD service account                               │
│        └─ Token for API access                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Scalability Considerations

```
Current Configuration (Development):
┌──────────────────────────────────────┐
│ Keycloak: 1 replica                  │
│ Developer Hub: 1 replica             │
│ PostgreSQL: StatefulSet (1 replica)  │
└──────────────────────────────────────┘

Production Configuration:
┌──────────────────────────────────────┐
│ Keycloak: 3 replicas                 │
│ Developer Hub: 3 replicas            │
│ PostgreSQL: External (RDS/Azure DB)  │
│ Resource limits configured           │
│ Pod anti-affinity rules              │
│ Horizontal Pod Autoscaling enabled   │
└──────────────────────────────────────┘
```

---

**This architecture ensures:**
- ✅ No hardcoded domains - works on any cluster
- ✅ GitOps-based deployment - version controlled
- ✅ Secure authentication - OIDC standard
- ✅ Plugin ecosystem - ArgoCD, Tekton, Kubernetes
- ✅ Scalable - can grow from dev to production

