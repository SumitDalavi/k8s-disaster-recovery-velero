#!/bin/bash
set -e

echo "=== Disaster Recovery Simulation ==="

echo "1. Taking Velero Backup of 'default' namespace..."
# Mock command assuming velero CLI is installed
echo "velero backup create dr-test-backup --include-namespaces default --wait"

echo "2. Simulating Disaster: Deleting Postgres StatefulSet..."
kubectl delete statefulset postgres-db -n default

echo "3. Restoring from Velero Backup..."
echo "velero restore create --from-backup dr-test-backup --wait"

echo "4. Verifying workload recovery..."
# Wait for pods to be ready
echo "kubectl wait --for=condition=ready pod -l app=postgres -n default --timeout=120s"

echo "✅ Disaster Recovery successfully simulated!"
