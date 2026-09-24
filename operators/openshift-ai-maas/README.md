# Parameterized package notes
#
# Secrets (never committed):
#   postgres-creds and maas-db-config in redhat-ods-applications must exist before
#   the postgres Deployment becomes Ready. The rosa-hcp-with-gitops Terraform overlay
#   creates them when deploy_rhoai_maas=true.
#
# Parameters:
#   Patch ConfigMap/rhoai-maas-params (see base/params-configmap.yaml) via Argo CD
#   kustomize patches. Terraform variables rhoai_maas_* drive those patches.
#
# Optional component:
#   components/sample-model — LLMInferenceService + MaaS governance CRs
