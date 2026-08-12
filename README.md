# Kubernetes Disaster Recovery & Chaos Lab 🌋💾

> A comprehensive Disaster Recovery architecture for Kubernetes using Velero, demonstrating RTO/RPO measurement, simulated cluster loss, and automated recovery runbooks.

## The Problem

Most teams claim to "do backups" because their cloud provider snapshots VMs. But in Kubernetes, cluster state is defined by hundreds of API objects (Deployments, Secrets, CRDs) combined with stateful Persistent Volumes. If a cluster is deleted or completely corrupted, restoring VM snapshots is insufficient. You need a way to restore the *Kubernetes State* and the *Data* to a brand new, empty cluster.

## The Solution

This project implements **Velero** as the core Disaster Recovery engine. 

1. **Backup Schedules**: Velero continuously backs up Kubernetes API objects to an Azure Blob Storage / AWS S3 bucket.
2. **Volume Snapshots**: Velero integrates with CSI drivers to snapshot Persistent Volumes (e.g., PostgreSQL databases) synchronously with the API objects.
3. **Recovery Runbooks**: Documented, tested procedures for standing up a new cluster and restoring the state from the backup bucket, achieving a measurable RTO (Recovery Time Objective).

## Why This Over the Obvious Alternative

The alternative is relying solely on GitOps (ArgoCD) to rebuild a cluster. While GitOps handles stateless applications perfectly, it *cannot* restore a stateful database volume, nor can it restore dynamic state (like dynamically generated secrets or user-created CRDs). A true DR strategy requires GitOps for the platform configuration *and* Velero for the stateful data/API backup.

## 🛠️ Tech Stack

- **Backup Engine**: Velero (VMware Tanzu)
- **Storage Backend**: Azure Blob Storage (or AWS S3)
- **Volume Snapshotter**: CSI Snapshotter

## Decision Log

| Decision | Rationale |
|----------|-----------|
| Velero over etcd snapshots | Etcd snapshots require access to the master nodes (impossible in managed services like AKS/EKS) and force you to restore to the exact same Kubernetes version. Velero backs up at the API level, allowing restores across different clusters and K8s versions. |
| Namespace-scoped Backups | Instead of one massive cluster backup, we define granular schedules per-namespace. This allows us to restore a single corrupted tenant without rolling back the entire cluster. |

## 📁 Project Structure

```
├── backups/
│   └── schedule-daily-full.yaml       # Daily Velero backup schedule CRD
├── restores/
│   └── restore-postgres-database.yaml # Targeted restore definition
├── runbooks/
│   └── CLUSTER_LOSS_RECOVERY.md       # Step-by-step RTO tested runbook
├── docs/ARCHITECTURE.md
└── README.md
```

## 👨‍💻 Author

*Built to demonstrate Site Reliability Engineering, RTO/RPO validation, and stateful Kubernetes operations.*
