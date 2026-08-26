#!/usr/bin/env bash
# Post-restore health verification
set -euo pipefail

NAMESPACES="${NAMESPACES:-default}"
log() { echo "[$(date -u +%H:%M:%S)] $*"; }
ok=0; fail=0

log "Starting post-restore health checks for namespaces: $NAMESPACES"

for ns in $(echo "$NAMESPACES" | tr ',' ' '); do
    log "--- Namespace: $ns ---"

    # Check all deployments are available
    DEPLOYMENTS=$(kubectl get deployments -n "$ns" -o json)
    TOTAL=$(echo "$DEPLOYMENTS" | python3 -c "import json,sys; print(len(json.load(sys.stdin)['items']))")
    READY=$(echo "$DEPLOYMENTS" | python3 -c "
import json,sys
items = json.load(sys.stdin)['items']
print(sum(1 for i in items if i.get('status',{}).get('availableReplicas',0) >= i.get('spec',{}).get('replicas',1)))
")
    log "Deployments: $READY/$TOTAL ready"
    [[ "$READY" -eq "$TOTAL" ]] && ((ok++)) || { ((fail++)); log "WARN: Not all deployments ready in $ns"; }

    # Check pods not in error state
    FAILED_PODS=$(kubectl get pods -n "$ns" --field-selector=status.phase=Failed -o name | wc -l)
    [[ "$FAILED_PODS" -gt 0 ]] && { log "WARN: $FAILED_PODS failed pods in $ns"; ((fail++)); } || ((ok++))

    # Check PVCs are bound
    UNBOUND=$(kubectl get pvc -n "$ns" -o json | python3 -c "
import json,sys
pvcs = json.load(sys.stdin)['items']
print(sum(1 for p in pvcs if p['status']['phase'] != 'Bound'))
")
    [[ "$UNBOUND" -gt 0 ]] && { log "WARN: $UNBOUND unbound PVCs in $ns"; ((fail++)); } || ((ok++))
done

log "Health check complete: $ok passed, $fail failed"
[[ "$fail" -eq 0 ]] && exit 0 || exit 1
