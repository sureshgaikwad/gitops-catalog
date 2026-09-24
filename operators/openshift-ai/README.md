# OpenShift AI (RHOAI) 3.5

GitOps package for Red Hat OpenShift AI.

## Layout

```
operators/openshift-ai/
  base/                         # NS, OG, Subscription, DSCI, DSC
  components/
    genai-ogx/                  # ogx Managed, llamastack Removed
    llamastack/                 # llamastack Managed, ogx Removed
    maas-enable/                # modelsAsAService Managed (after RHCL + gateway)
  kustomization.yaml            # default: base only
```

## Parameters

| Item | How to override |
|------|-----------------|
| Subscription channel (default `stable-3.5`) | Argo CD kustomize patch on `Subscription/rhods-operator` (Terraform `rhoai_channel`) |
| Gen AI backend | Argo CD `kustomize.components`: `components/genai-ogx` or `components/llamastack` |
| Enable MaaS on DSC | Argo CD component `components/maas-enable` (after `operators/rhcl-operator` + `operators/openshift-ai-maas`) |

Do not commit cluster-specific hostnames or secrets here. MaaS gateway / model params live in `operators/openshift-ai-maas`.
