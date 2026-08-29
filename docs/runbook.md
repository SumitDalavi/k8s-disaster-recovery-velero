# Runbook — k8s-disaster-recovery-velero
> Last updated: 2026-08-29

## Quick Start
```bash
# Bring up the cluster and deploy Velero
kind create cluster --name dr-lab
kubectl create namespace velero
helm repo add minio https://charts.min.io/
helm install minio minio/minio --namespace velero --set resources.requests.memory=256Mi
# Configure velero with MinIO backend
```

## Run Tests / Demos
```bash
# Backup
velero backup create demo-backup --include-namespaces demo-app
# Simulate disaster
kubectl delete namespace demo-app
# Restore
velero restore create --from-backup demo-backup
```

## Failure Modes
| Symptom | Cause | Fix |
|---|---|---|
| Backup hangs in InProgress | Storage backend unreachable | Check MinIO pods and Velero BSL (BackupStorageLocation) configuration |
