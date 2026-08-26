#!/usr/bin/env bash
# Point-in-time restore from a Velero backup
set -euo pipefail

BACKUP_NAME="${1:-}"
RESTORE_NAME="${2:-restore-$(date +%Y%m%d-%H%M%S)}"
NAMESPACES="${NAMESPACES:-}"

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

[[ -z "$BACKUP_NAME" ]] && { log "Usage: $0 <backup-name> [restore-name]"; exit 1; }

log "Restoring from backup: $BACKUP_NAME"
log "Restore name: $RESTORE_NAME"

# Confirm backup exists
velero backup get "$BACKUP_NAME" || { log "ERROR: Backup $BACKUP_NAME not found"; exit 1; }

# Build restore command
CMD="velero restore create $RESTORE_NAME --from-backup $BACKUP_NAME --wait"
[[ -n "$NAMESPACES" ]] && CMD="$CMD --include-namespaces $NAMESPACES"

log "Running: $CMD"
eval "$CMD"

STATUS=$(velero restore get "$RESTORE_NAME" -o json | python3 -c "import json,sys; print(json.load(sys.stdin)['status']['phase'])" 2>/dev/null || echo "Unknown")
log "Restore status: $STATUS"

if [[ "$STATUS" == "Completed" ]]; then
    log "SUCCESS: Restore $RESTORE_NAME completed"
    velero restore describe "$RESTORE_NAME"
else
    log "WARNING: Restore finished with status: $STATUS"
    velero restore logs "$RESTORE_NAME" | tail -20
    [[ "$STATUS" == "PartiallyFailed" ]] && exit 2
    exit 1
fi
