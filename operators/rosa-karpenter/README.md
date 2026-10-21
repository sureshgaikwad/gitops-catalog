# rosa-karpenter (NodePools for Red Hat build of Karpenter)

This is **not** an OLM operator. On ROSA HCP, Karpenter controllers run in the
hosted control plane. Enable AutoNode with Terraform (`enable_karpenter = true`),
then sync this path to create `NodePool` CRs.

## Enable (cluster stack)

```hcl
enable_karpenter = true
```

That creates `rosa-karpenter-controller-role-<cluster>` and sets:

```hcl
auto_node = { mode = "enabled", role_arn = "..." }
```

## Day-2 GitOps

```hcl
deploy_rosa_karpenter = true
```

Argo CD Application path: `operators/rosa-karpenter`

## Verify

```bash
oc get openshiftec2nodeclass   # ROSA-managed default
oc get ec2nodeclass            # synced companion for NodePool nodeClassRef
oc get nodepool.karpenter.sh
oc get nodeclaim
oc get nodes -l autonode=true
```

NodePools must use `nodeClassRef.kind: EC2NodeClass` (group `karpenter.k8s.aws`) with the OpenshiftEC2NodeClass name.
