#!/bin/bash
# Setup script for Developer Hub with Keycloak GitOps deployment

set -e

echo "=================================="
echo "Developer Hub GitOps Setup Script"
echo "=================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if oc is installed
if ! command -v oc &> /dev/null; then
    echo -e "${RED}Error: oc CLI not found. Please install it first.${NC}"
    exit 1
fi

# Check if logged in
if ! oc whoami &> /dev/null; then
    echo -e "${RED}Error: Not logged into OpenShift. Please login first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Connected to OpenShift cluster: $(oc whoami --show-server)"
echo ""

# Step 1: Install OpenShift GitOps Operator
echo "Step 1: Installing OpenShift GitOps Operator..."
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

echo -e "${GREEN}✓${NC} OpenShift GitOps Operator subscription created"
echo "   Waiting for operator to be ready..."
sleep 30

# Wait for CSV to be ready
for i in {1..30}; do
    if oc get csv -n openshift-operators | grep -q "gitops.*Succeeded"; then
        echo -e "${GREEN}✓${NC} OpenShift GitOps Operator is ready"
        break
    fi
    echo "   Still waiting... ($i/30)"
    sleep 10
done

# Step 2: Grant cluster-admin to ArgoCD
echo ""
echo "Step 2: Granting cluster-admin to ArgoCD..."
oc adm policy add-cluster-role-to-user cluster-admin \
  system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller

echo -e "${GREEN}✓${NC} Cluster-admin granted to ArgoCD"

# Step 3: Get ArgoCD URL and credentials
echo ""
echo "Step 3: Getting ArgoCD credentials..."
ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "Not yet available")
ARGOCD_PASSWORD=$(oc get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' 2>/dev/null | base64 -d || echo "Not yet available")

if [ "$ARGOCD_ROUTE" != "Not yet available" ]; then
    echo -e "${GREEN}✓${NC} ArgoCD URL: https://$ARGOCD_ROUTE"
    echo -e "${GREEN}✓${NC} Username: admin"
    echo -e "${GREEN}✓${NC} Password: $ARGOCD_PASSWORD"
else
    echo -e "${YELLOW}⚠${NC}  ArgoCD not ready yet, wait a few moments and check manually"
fi

# Step 4: Configure Git repository
echo ""
echo "Step 4: Git Repository Configuration"
echo "-------------------------------------"
echo -e "${YELLOW}ACTION REQUIRED:${NC}"
echo "1. Fork/clone this repository to your Git server"
echo "2. Update argocd/*.yaml files with your Git repository URL"
echo ""
read -p "Enter your Git repository URL: " GIT_REPO
if [ -n "$GIT_REPO" ]; then
    echo "   Updating application manifests..."
    for file in argocd/*.yaml; do
        sed -i.bak "s|https://github.com/YOUR-ORG/gitops-devhub.git|$GIT_REPO|g" "$file"
    done
    echo -e "${GREEN}✓${NC} Updated ArgoCD application manifests with: $GIT_REPO"
fi

# Step 5: Generate secrets
echo ""
echo "Step 5: Generating Secrets"
echo "-------------------------------------"
read -p "Generate new client and session secrets? (yes/no): " GEN_SECRETS
if [ "$GEN_SECRETS" = "yes" ]; then
    CLIENT_SECRET=$(openssl rand -base64 32)
    SESSION_SECRET=$(openssl rand -base64 32)
    
    echo "   Updating secrets..."
    sed -i.bak "s|MTQLOQRT1pXkxLyXCyHzlRavSiofUZJ7|$CLIENT_SECRET|g" base/keycloak/keycloak-client.yaml
    sed -i.bak "s|MTQLOQRT1pXkxLyXCyHzlRavSiofUZJ7|$CLIENT_SECRET|g" base/developer-hub/auth-secret.yaml
    sed -i.bak "s|U1nyHYCTIcm0LbPSBUDBiRvv8I8emzA2tSSStz2ydFI=|$SESSION_SECRET|g" base/developer-hub/auth-secret.yaml
    
    echo -e "${GREEN}✓${NC} Generated new secrets"
    echo "   Client Secret: $CLIENT_SECRET"
    echo "   Session Secret: $SESSION_SECRET"
fi

# Step 6: Summary
echo ""
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Review and customize configurations in base/ directory"
echo "2. Update user entities in base/developer-hub/user-entities.yaml"
echo "3. Commit and push changes to your Git repository"
echo "4. Deploy using: oc apply -f argocd/app-of-apps.yaml"
echo ""
echo "For detailed instructions, see DEPLOYMENT_GUIDE.md"
echo ""
if [ "$ARGOCD_ROUTE" != "Not yet available" ]; then
    echo "ArgoCD UI: https://$ARGOCD_ROUTE"
    echo "Username: admin"
    echo "Password: $ARGOCD_PASSWORD"
fi
echo ""

