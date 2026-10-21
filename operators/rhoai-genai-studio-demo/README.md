# rhoai-genai-studio-demo

GitOps bootstrap for the **RHOAI GenAI Studio** guardrails + MLflow tracing demo
pattern from [micytao/rhoai-demo-guide](https://github.com/micytao/rhoai-demo-guide).

## What this path syncs

| Resource | Purpose |
|----------|---------|
| Namespace `demo` | Dashboard-visible Data Science project |
| `rhoai-genai-studio-demo-params` | Cluster values (patched by day-2 Terraform) |
| `MLflow` CR | Workspace-scoped MLflow for playground traces |

Playground (`OGXServer`), `NemoGuardrails`, PgVector, and OTEL wiring are created
by the idempotent setup script (operator-safe workarounds cannot live purely in GitOps).

## Enable (day-2 overlay)

```hcl
deploy_rhoai_genai_studio_demo = true
# implies MaaS + OGX + MLflow operator
```

Then after Argo is healthy and a MaaS model is subscribed:

```bash
# From suresh-rosa-automation repo root
./scripts/setup-genai-studio-mlflow-tracing.sh --namespace demo
```

## Docs

- Automation repo: `docs/rhoai-genai-studio-demo.md` and `docs/rhoai-genai-studio-demo-flow.md`
- Script: `scripts/setup-genai-studio-mlflow-tracing.sh`
- Upstream: https://github.com/micytao/rhoai-demo-guide
