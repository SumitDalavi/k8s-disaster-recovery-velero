# Disaster Recovery Drill: RTO & RPO Results

**Date:** 2026-08-29  
**Target:** `demo-app` namespace (simulating stateful app)  

## Objectives

- **Target RPO (Recovery Point Objective):** 24 hours (Daily backups)
- **Target RTO (Recovery Time Objective):** < 15 minutes for namespace recovery.

## Drill Execution

1. **Simulated Disaster (T=0):** 
   - Command: `kubectl delete namespace demo-app`
   - State: Application offline. All API objects and (simulated) volumes deleted.
2. **Detection & Response (T+2m):** 
   - Incident acknowledged.
3. **Recovery Initiated (T+3m):** 
   - Command: `velero restore create --from-backup demo-backup`
4. **Recovery Complete (T+4m):**
   - Velero restore marked as `Completed`.

## Measured Results

| Metric | Measured Value | Status | Notes |
|---|---|---|---|
| **RPO (Data Loss)** | 4 hours | ✅ Meets Objective | Restored from the scheduled backup taken 4 hours prior to the disaster. |
| **RTO (Downtime)** | 4 minutes | ✅ Meets Objective | API objects (deployments, configmaps) restored instantly. Pod initialization took ~20 seconds. |

## Data Recovery Verification

Following the restore, the following verification checks were performed:

1. **Workloads Running:** `kubectl get pods -n demo-app` showed all pods in `Running` state.
2. **State Restored:** `kubectl get configmap app-config -n demo-app -o yaml` showed the exact configuration state present at the time of backup (`env: production`).
3. **Connectivity:** Service endpoints successfully routed traffic to the restored pods.

**Conclusion:** The Velero-based DR strategy successfully met business RTO/RPO requirements for catastrophic namespace loss.
