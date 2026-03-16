# Developer Hub (Red Hat Developer Hub) GitOps configs

## Before syncing to Git

1. **Replace `{{CLUSTER_DOMAIN}}` in `base/app-config.yaml`**  
   Set your OpenShift cluster domain so Backstage URLs are correct. Example:
   ```bash
   oc get ingress.config.openshift.io cluster -o jsonpath='{.spec.domain}'
   ```
   Replace every `{{CLUSTER_DOMAIN}}` in `base/app-config.yaml` with that value (e.g. `rosa.xxxx.p1.openshiftapps.com`).

2. **Sync order (ArgoCD)**  
   Resources use sync-waves so dependencies apply first:
   - **Wave 0:** Namespaces
   - **Wave 1:** ConfigMap `developer-hub-app-config`, PVC `dynamic-plugins-root`
   - **Wave 2:** Backstage instance (depends on the ConfigMap)

   The PVC uses the default StorageClass (WaitForFirstConsumer) and will bind when the Backstage pod is created and scheduled.

## Kustomize

Apply from this directory (or point Argo at it):

```bash
kubectl apply -k .
```

Or from repo root:

```bash
kubectl apply -k operators/developer-hub/
```
