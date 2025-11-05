# Red Hat Build of Keycloak (RHBK) Configuration

This directory contains the complete GitOps configuration for deploying Red Hat Build of Keycloak with authentication setup for Developer Hub.

## Contents

### Base Configuration (`base/`)

- **rhbk-namespace.yaml** - Namespace for Keycloak (`rhbk`)
- **rhbk-operator.yaml** - RHBK Operator subscription and OperatorGroup
- **keycloak-instance.yaml** - Keycloak server instance with PostgreSQL database
- **keycloak-realm.yaml** - Realm configuration (`myrealm`) with users
- **keycloak-client.yaml** - OIDC client for Developer Hub (`myclient`)

### Overlays

- **overlays/production/** - Production-specific configurations

## Deployment

### Quick Deploy

```bash
# Deploy base configuration
oc apply -k base/

# Or deploy production overlay
oc apply -k overlays/production/
```

### Deployment Order (via ArgoCD sync waves)

1. **Wave 0**: Namespace
2. **Wave 1**: Operator (OperatorGroup + Subscription)
3. **Wave 2**: Keycloak instance + PostgreSQL
4. **Wave 3**: Realm + Client configuration

## Configuration Details

### Namespace
- **Name**: `rhbk`
- **Purpose**: Hosts Keycloak and its dependencies

### Keycloak Instance
- **Name**: `sample-kc`
- **Replicas**: 1
- **Database**: PostgreSQL (StatefulSet)
- **Storage**: 1Gi PVC per replica

### Realm
- **Name**: `myrealm`
- **Users**: Configured in `keycloak-realm.yaml`
- **Settings**: External SSL required, login with email enabled

### OIDC Client
- **Client ID**: `myclient`
- **Type**: Confidential
- **Secret**: Defined in `keycloak-client.yaml` ⚠️ **CHANGE IN PRODUCTION**
- **Redirect URIs**: Pre-configured for Developer Hub
- **Scopes**: openid, email, profile, roles, groups

## URLs (After Deployment)

```bash
# Get Keycloak URL
oc get route -n rhbk -o jsonpath='{.items[0].spec.host}'
```

Default URL pattern: `https://sample-kc-service-rhbk.apps.<cluster-domain>`

## Credentials

### PostgreSQL Database
- **Username**: `keycloak`
- **Password**: `keycloak` ⚠️ **CHANGE IN PRODUCTION**
- **Database**: `keycloak`
- **Secret**: `keycloak-db-secret`

### Keycloak Admin
- **Username**: `admin`
- **Password**: Auto-generated, retrieve with:
  ```bash
  oc get secret sample-kc-initial-admin -n rhbk -o jsonpath='{.data.password}' | base64 -d
  ```

### OIDC Client
- **Client ID**: `myclient`
- **Client Secret**: Defined in `keycloak-client.yaml`

## Customization

### Update Redirect URIs

After deploying Developer Hub, update the redirect URIs in `keycloak-client.yaml`:

```yaml
redirectUris:
  - "https://<your-developer-hub-url>/api/auth/oidc/handler/frame"
  - "https://<your-developer-hub-url>/api/auth/oidc/handler/frame/*"
  - "https://<your-developer-hub-url>/*"
webOrigins:
  - "https://<your-developer-hub-url>"
```

### Add Users

Edit `keycloak-realm.yaml` to add more users:

```yaml
users:
  - username: "newuser"
    email: "newuser@example.com"
    firstName: "New"
    lastName: "User"
    enabled: true
    emailVerified: true
    credentials:
      - type: "password"
        value: "changeme"
        temporary: false
```

### Change Client Secret

Generate a new secret:
```bash
openssl rand -base64 32
```

Update in `keycloak-client.yaml`:
```yaml
secret: "<new-secret>"
```

Also update in Developer Hub secret!

## Verification

### Check Operator
```bash
oc get csv -n rhbk
```

### Check Keycloak Instance
```bash
oc get keycloak -n rhbk
oc get pods -n rhbk
```

### Check Realm and Client
```bash
oc get keycloakrealmimport -n rhbk
```

### Access Keycloak Admin Console
```bash
KEYCLOAK_URL=$(oc get route -n rhbk -o jsonpath='{.items[0].spec.host}')
echo "https://$KEYCLOAK_URL"
```

## Troubleshooting

### Keycloak Not Starting

```bash
# Check pod logs
oc logs -f $(oc get pod -n rhbk -l app=keycloak -o name) -n rhbk

# Check events
oc get events -n rhbk --sort-by='.lastTimestamp'

# Check PostgreSQL
oc get pods -n rhbk | grep postgresql
```

### Realm/Client Not Applied

```bash
# Check KeycloakRealmImport status
oc get keycloakrealmimport -n rhbk -o yaml

# Re-apply
oc apply -f base/keycloak-realm.yaml
oc apply -f base/keycloak-client.yaml
```

## Security Notes

⚠️ **Before Production:**

1. **Change Database Password**
   - Update `keycloak-db-secret` with strong password
   - Update Keycloak instance to use new secret

2. **Change OIDC Client Secret**
   - Generate new secret: `openssl rand -base64 32`
   - Update both Keycloak client and Developer Hub configurations

3. **Use External PostgreSQL**
   - For production, use external managed database
   - Update `keycloak-instance.yaml` with external DB details

4. **Configure Proper TLS**
   - Use valid certificates (not self-signed)
   - Update `keycloak-instance.yaml` with proper tls configuration

5. **Enable Proper Authentication**
   - Configure appropriate password policies
   - Enable MFA if required
   - Set up proper user federation (LDAP/AD) if needed

## Integration with Developer Hub

This Keycloak configuration is designed to work with the Developer Hub configuration in the `developer-hub/` directory.

Required Developer Hub configuration:
- OIDC metadata URL pointing to this Keycloak instance
- Client ID: `myclient`
- Client secret matching the one defined here
- User entities with emails matching Keycloak users

See `../developer-hub/README.md` for Developer Hub configuration details.

## References

- [RHBK Documentation](https://access.redhat.com/documentation/en-us/red_hat_build_of_keycloak)
- [Keycloak Operator](https://www.keycloak.org/operator/installation)
- [OIDC Configuration](https://www.keycloak.org/docs/latest/securing_apps/#_oidc)

---

**Part of the Developer Hub Stack GitOps Configuration**

