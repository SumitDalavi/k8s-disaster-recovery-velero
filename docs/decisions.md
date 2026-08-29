# Decisions

## ADR-001: Velero over etcd Snapshots for DR
**Date:** 2026-08-29  
**Status:** Accepted

**Context:**  
We need a standardized Disaster Recovery mechanism for Kubernetes clusters.

**Decision:**  
We chose Velero API-level backups instead of etcd snapshots.

**Consequences:**  
- ✅ Works across managed Kubernetes (EKS, AKS, GKE) where etcd access is prohibited.
- ✅ Allows restoring specific namespaces rather than rolling back the entire cluster.
- ✅ Enables migration to new clusters/K8s versions during a disaster.
- ⚠️ Slower than block-level restores.
