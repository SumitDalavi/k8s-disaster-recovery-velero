# Incident Runbook: Total Cluster Loss

**Scenario**: The primary production AKS/EKS cluster has been deleted or fatally corrupted.
**Target RTO (Recovery Time Objective)**: 45 minutes
**Target RPO (Recovery Point Objective)**: 24 hours (based on daily backups)

## Phase 1: Provision Clean Cluster (T+0 mins)
1. Run the Terraform pipeline to provision a new, empty Kubernetes cluster in the DR region.
2. Obtain kubeconfig for the new cluster.

## Phase 2: Bootstrap Velero (T+15 mins)
1. Install the Velero CLI on your jumpbox.
2. Install Velero into the new cluster, pointing it to the existing Azure Blob/S3 backup bucket:
   ```bash
   velero install \
       --provider azure \
       --plugins velero/velero-plugin-for-microsoft-azure:v1.5.0 \
       --bucket my-dr-backups \
       --secret-file ./credentials-velero \
       --use-volume-snapshots=true
   ```

## Phase 3: Initiate Restore (T+20 mins)
1. Verify Velero can see the backups in the bucket:
   ```bash
   velero backup get
   ```
2. Identify the most recent successful backup (e.g., `daily-production-backup-20260812`).
3. Trigger the full cluster restore:
   ```bash
   velero restore create --from-backup daily-production-backup-20260812
   ```

## Phase 4: Validation (T+40 mins)
1. Check restore status: `velero restore get`
2. Verify Persistent Volumes are bound: `kubectl get pvc -A`
3. Update global DNS (Route53 / Azure Traffic Manager) to point to the new cluster's Ingress IP.
