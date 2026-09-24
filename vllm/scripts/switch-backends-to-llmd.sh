#!/usr/bin/env bash
set -euo pipefail

# Switch semantic-router backend endpoints from current predictors
# to llm-d gateway service ClusterIPs.
#
# Usage:
#   MODEL_NS=models \
#   QWEN_LLMD_SVC=<qwen-llmd-gateway-service> \
#   PHI_LLMD_SVC=<phi-llmd-gateway-service> \
#   ./scripts/switch-backends-to-llmd.sh

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROUTER_CFG="${WORKDIR}/04-configmap-router.yaml"
MODEL_NS="${MODEL_NS:-models}"

: "${QWEN_LLMD_SVC:?QWEN_LLMD_SVC is required}"
: "${PHI_LLMD_SVC:?PHI_LLMD_SVC is required}"

qwen_ip="$(oc get svc "${QWEN_LLMD_SVC}" -n "${MODEL_NS}" -o jsonpath='{.spec.clusterIP}')"
phi_ip="$(oc get svc "${PHI_LLMD_SVC}" -n "${MODEL_NS}" -o jsonpath='{.spec.clusterIP}')"

if [[ -z "${qwen_ip}" || -z "${phi_ip}" ]]; then
  echo "Failed to resolve one or both llm-d service ClusterIPs."
  exit 1
fi

python3 - "${ROUTER_CFG}" "${qwen_ip}" "${phi_ip}" <<'PYEOF'
import re
import sys
from pathlib import Path

cfg_path = Path(sys.argv[1])
qwen_ip = sys.argv[2]
phi_ip = sys.argv[3]
text = cfg_path.read_text()

qwen_pat = re.compile(
    r'(- name: "qwen-endpoint"\n\s+address: ")([^"]+)(")',
    re.MULTILINE,
)
phi_pat = re.compile(
    r'(- name: "phi-endpoint"\n\s+address: ")([^"]+)(")',
    re.MULTILINE,
)

new_text = qwen_pat.sub(rf'\1{qwen_ip}\3', text, count=1)
new_text = phi_pat.sub(rf'\1{phi_ip}\3', new_text, count=1)

if new_text == text:
    raise SystemExit("Did not find endpoint address fields to update.")

cfg_path.write_text(new_text)
print(f"Updated {cfg_path} with qwen={qwen_ip}, phi={phi_ip}")
PYEOF

echo "Applying updated config and restarting semantic router..."
oc apply -f "${ROUTER_CFG}"
oc rollout restart deployment/semantic-router-kserve -n "${MODEL_NS}"
oc rollout status deployment/semantic-router-kserve -n "${MODEL_NS}" --timeout=300s

echo "Done. Current backend addresses:"
oc get configmap semantic-router-kserve-config -n "${MODEL_NS}" -o yaml
