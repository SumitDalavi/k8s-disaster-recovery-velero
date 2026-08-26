#!/usr/bin/env bash
# Automated DR test: backup → simulate failure → restore → verify
set -euo pipefail

TEST_NS="${DR_TEST_NS:-dr-test}"
log() { echo "[$(date -u +%H:%M:%S)] $*"; }

log "=== DR Test Starting ==="
log "Test namespace: $TEST_NS"

# 1. Create test workload
log "Step 1: Deploying test workload..."
kubectl create namespace "$TEST_NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment dr-test-app --image=nginx:1.25 -n "$TEST_NS" --dry-run=client -o yaml | kubectl apply -f -
kubectl wait deployment/dr-test-app -n "$TEST_NS" --for=condition=Available --timeout=60s

# 2. Backup
log "Step 2: Creating backup..."
BACKUP_NAME="dr-test-$(date +%Y%m%d-%H%M%S)"
BACKUP_NAME="$BACKUP_NAME" NAMESPACES="$TEST_NS" bash scripts/backup.sh

# 3. Simulate failure (delete namespace)
log "Step 3: Simulating failure — deleting namespace $TEST_NS..."
kubectl delete namespace "$TEST_NS" --wait=true

# 4. Restore
log "Step 4: Restoring from backup $BACKUP_NAME..."
bash scripts/restore.sh "$BACKUP_NAME"

# 5. Verify
log "Step 5: Verifying restore..."
kubectl wait deployment/dr-test-app -n "$TEST_NS" --for=condition=Available --timeout=120s

NAMESPACES="$TEST_NS" bash scripts/verify-restore.sh
log "=== DR Test PASSED ==="

# Cleanup
kubectl delete namespace "$TEST_NS" --ignore-not-found
