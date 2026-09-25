# OpenShift AI MaaS (Models-as-a-Service) — ROSA essentials
#
# Includes the workshop pieces required for ROSA/cloud:
# - LoadBalancer Gateway (maas-default-gateway) — not ClusterIP
# - Postgres (secrets created by Terraform, not in git)
# - User Workload Monitoring
# - Istio Telemetry + Kuadrant TelemetryPolicy
# - ODHDashboardConfig (MaaS + Gen AI + Observability nav)
# - PersesGlobalDatasource (Usage tab)
# - Optional sample-model component (LLMInferenceService + MaaS CRs)
#
# Related operators (wired by Terraform when deploy_rhoai_maas=true):
# - operators/rhcl-operator
# - operators/cert-manager-operator
# - operators/leader-worker-set
# - operators/jobset-operator
# - operators/cluster-observability-operator
# - operators/opentelemetry-operator
#
# Parameters: patch ConfigMap/rhoai-maas-params via Argo/Terraform (hostname, TLS secret, model URI).
