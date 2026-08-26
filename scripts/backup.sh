#!/usr/bin/env bash
# Full cluster backup using Velero with S3 backend
set -euo pipefail

BACKUP_NAME="${BACKUP_NAME:-full-backup-$(date +%Y%m%d-%H%M%S)}"
TTL="${BACKUP_TTL:-720h}"      # 30 days retention
NAMESPACES="${NAMESPACES:-}"   # empty = all namespaces

log() { echo "[$(date -u +%H:%M:%S)] $*"; }

log "Starting Velero backup: $BACKUP_NAME"

# Check Velero is available and connected
velero version --client-only || { log "ERROR: Velero not installed"; exit 1; }

# Build backup command
CMD="velero backup create $BACKUP_NAME --ttl $TTL --wait"
[[ -n "$NAMESPACES" ]] && CMD="$CMD --include-namespaces $NAMESPACES"

log "Running: $CMD"
eval "$CMD"

# Verify backup succeeded
STATUS=$(velero backup get "$BACKUP_NAME" -o json | python3 -c "import json,sys; print(json.load(sys.stdin)['status']['phase'])" 2>/dev/null || echo "Unknown")
log "Backup status: $STATUS"

if [[ "$STATUS" == "Completed" ]]; then
    log "SUCCESS: Backup $BACKUP_NAME completed"
    velero backup describe "$BACKUP_NAME" --details
    exit 0
else
    log "FAILURE: Backup $BACKUP_NAME ended with status: $STATUS"
    velero backup logs "$BACKUP_NAME" | tail -20
    exit 1
fi
