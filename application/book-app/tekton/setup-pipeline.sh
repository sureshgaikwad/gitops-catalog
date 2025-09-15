#!/bin/bash

# Tekton Pipeline Setup Script for Bookstore Application
# This script sets up a complete CI/CD pipeline with GitHub webhooks

echo "🚀 Setting up Tekton Pipeline for Bookstore Application"
echo "======================================================="

# Check if OpenShift Pipelines operator is installed
echo "📋 Checking OpenShift Pipelines operator status..."
if ! oc get csv -n openshift-operators | grep -q "openshift-pipelines-operator"; then
    echo "❌ OpenShift Pipelines operator not found. Please install it first."
    echo "   Run: oc apply -f - <<EOF"
    echo "   apiVersion: operators.coreos.com/v1alpha1"
    echo "   kind: Subscription"
    echo "   metadata:"
    echo "     name: openshift-pipelines-operator"
    echo "     namespace: openshift-operators"
    echo "   spec:"
    echo "     channel: pipelines-1.15"
    echo "     name: openshift-pipelines-operator-rh"
    echo "     source: redhat-operators"
    echo "     sourceNamespace: openshift-marketplace"
    echo "   EOF"
    exit 1
fi

# Wait for Tekton CRDs to be available
echo "⏳ Waiting for Tekton CRDs to be available..."
until oc get crd pipelines.tekton.dev &>/dev/null; do
    echo "   Waiting for Tekton CRDs..."
    sleep 10
done
echo "✅ Tekton CRDs are available"

# Ensure we're in the correct namespace
echo "🏢 Setting up namespace..."
oc project sgaikwad || oc new-project sgaikwad

# Step 1: Create Quay.io authentication secret
echo "🔐 Please enter your Quay.io credentials:"
read -p "Quay.io Username [sureshgaikwad]: " QUAY_USERNAME
QUAY_USERNAME=${QUAY_USERNAME:-sureshgaikwad}

read -s -p "Quay.io Password: " QUAY_PASSWORD
echo

read -p "Quay.io Email: " QUAY_EMAIL

echo "📝 Creating Quay.io authentication secret..."
oc create secret docker-registry quay-auth-secret \
  --docker-server=quay.io \
  --docker-username="${QUAY_USERNAME}" \
  --docker-password="${QUAY_PASSWORD}" \
  --docker-email="${QUAY_EMAIL}" \
  -n sgaikwad --dry-run=client -o yaml | oc apply -f -

oc annotate secret quay-auth-secret tekton.dev/docker-0=https://quay.io -n sgaikwad

echo "✅ Quay.io secret created successfully"

# Step 2: Create ServiceAccount and RBAC
echo "👤 Creating ServiceAccount and RBAC..."
oc apply -f 02-service-account.yaml

echo "✅ ServiceAccount and RBAC created successfully"

# Step 3: Create GitHub webhook secret
echo "🔒 Creating GitHub webhook secret..."
WEBHOOK_SECRET=$(openssl rand -hex 20)
echo "Generated webhook secret: ${WEBHOOK_SECRET}"
echo "Save this secret - you'll need it for GitHub webhook configuration!"

oc create secret generic github-webhook-secret \
  --from-literal=webhook-secret="${WEBHOOK_SECRET}" \
  -n sgaikwad --dry-run=client -o yaml | oc apply -f -

echo "✅ GitHub webhook secret created"

# Step 4: Create Pipeline
echo "🔧 Creating Tekton Pipeline..."
oc apply -f 03-pipeline.yaml

echo "✅ Pipeline created successfully"

# Step 5: Create Triggers
echo "🎯 Creating Tekton Triggers..."
oc apply -f 04-triggers.yaml

echo "✅ Triggers created successfully"

# Step 6: Get webhook URL
echo "🌐 Getting webhook URL..."
sleep 10  # Wait for route to be created
WEBHOOK_URL=$(oc get route bookstore-webhook-route -n sgaikwad -o jsonpath='{.spec.host}')

echo "📋 Setup Summary"
echo "================"
echo "✅ Pipeline: bookstore-ci-pipeline"
echo "✅ EventListener: bookstore-event-listener"
echo "✅ Webhook URL: https://${WEBHOOK_URL}"
echo "✅ Webhook Secret: ${WEBHOOK_SECRET}"
echo ""
echo "🔧 Next Steps:"
echo "1. Go to your GitHub repository: https://github.com/sureshgaikwad/sample-bookstore-application"
echo "2. Navigate to Settings > Webhooks"
echo "3. Click 'Add webhook'"
echo "4. Set Payload URL to: https://${WEBHOOK_URL}"
echo "5. Set Content type to: application/json"
echo "6. Set Secret to: ${WEBHOOK_SECRET}"
echo "7. Select 'Just the push event'"
echo "8. Click 'Add webhook'"
echo ""
echo "🚀 Your CI/CD pipeline is now ready!"
echo "Any push to the main branch will trigger a new build and deployment."
