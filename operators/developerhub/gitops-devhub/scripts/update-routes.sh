#!/bin/bash
# Script to update routes after initial deployment

set -e

echo "Updating routes in GitOps configurations..."
echo ""

# Get current routes from cluster
echo "Getting routes from cluster..."
KEYCLOAK_ROUTE=$(oc get route -n rhbk -o jsonpath='{.items[0].spec.host}' 2>/dev/null || echo "")
DEVHUB_ROUTE=$(oc get route -n demo-project -o jsonpath='{.items[0].spec.host}' 2>/dev/null || echo "")

if [ -z "$KEYCLOAK_ROUTE" ]; then
    echo "Error: Keycloak route not found. Make sure Keycloak is deployed."
    echo "Trying manual input..."
    read -p "Enter Keycloak route: " KEYCLOAK_ROUTE
fi

if [ -z "$DEVHUB_ROUTE" ]; then
    echo "Error: Developer Hub route not found. Make sure Developer Hub is deployed."
    echo "Trying manual input..."
    read -p "Enter Developer Hub route: " DEVHUB_ROUTE
fi

echo ""
echo "Found routes:"
echo "  Keycloak: https://$KEYCLOAK_ROUTE"
echo "  Developer Hub: https://$DEVHUB_ROUTE"
echo ""

# Update Keycloak client configuration
echo "Updating Keycloak client configuration..."
sed -i.bak "s|backstage-developer-hub-demo-project.apps.rosa.sgaikwad.a98d.p3.openshiftapps.com|$DEVHUB_ROUTE|g" base/keycloak/keycloak-client.yaml
echo "✓ Updated base/keycloak/keycloak-client.yaml"

# Update Developer Hub app-config
echo "Updating Developer Hub configuration..."
sed -i.bak "s|backstage-developer-hub-demo-project.apps.rosa.sgaikwad.a98d.p3.openshiftapps.com|$DEVHUB_ROUTE|g" base/developer-hub/app-config.yaml
sed -i.bak "s|sample-kc-service-rhbk.apps.rosa.sgaikwad.a98d.p3.openshiftapps.com|$KEYCLOAK_ROUTE|g" base/developer-hub/app-config.yaml
echo "✓ Updated base/developer-hub/app-config.yaml"

echo ""
echo "Routes updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit: git add . && git commit -m 'Update routes'"
echo "3. Push: git push"
echo "4. ArgoCD will automatically sync the changes"
echo ""

