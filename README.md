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


## ðŸ“‹ Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | >= 1.28 | Kubernetes CLI |
| [kind](https://kind.sigs.k8s.io/) or [minikube](https://minikube.sigs.k8s.io/) | Latest | Local K8s cluster |
| [Velero CLI](https://velero.io/docs/main/basic-install/) | >= 1.12 | Backup/restore CLI |
| [Helm](https://helm.sh/) | >= 3.x | Package manager |
| [MinIO](https://min.io/) (optional) | Latest | Local S3-compatible storage for backups |

## ðŸš€ Step-by-Step Setup

### Option A: Local Cluster (kind) with MinIO

```bash
# 1. Clone the repository
git clone https://github.com/SumitDalavi/k8s-disaster-recovery-velero.git
cd k8s-disaster-recovery-velero

# 2. Create a local cluster
kind create cluster --name dr-lab

# 3. Install MinIO as local backup storage
kubectl create namespace velero
helm repo add minio https://charts.min.io/
helm install minio minio/minio --namespace velero --set resources.requests.memory=256Mi

# 4. Install Velero with MinIO backend
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket velero-backups \
  --secret-file ./credentials-velero \
  --backup-storage-location-config region=minio,s3ForcePathStyle=true,s3Url=http://minio.velero:9000 \
  --use-volume-snapshots=false

# 5. Deploy a sample application to backup
kubectl create namespace demo-app
kubectl run nginx --image=nginx --namespace=demo-app
kubectl create configmap app-config --from-literal=env=production --namespace=demo-app
```

### Option B: Existing Cloud Cluster

```bash
# Use cloud-native storage (AWS S3, Azure Blob, GCS) instead of MinIO
# Follow Velero's cloud provider documentation for installation
```

## ðŸ§ª Usage & Demo â€” Backup & Disaster Recovery

### Step 1: Create an on-demand backup
```bash
velero backup create demo-backup --include-namespaces demo-app
velero backup describe demo-backup
velero backup logs demo-backup
```

### Step 2: Schedule automated backups
```bash
kubectl apply -f backups/schedule-daily-full.yaml
velero schedule get
```

### Step 3: Simulate a disaster
```bash
# Delete the entire namespace (simulating data loss)
kubectl delete namespace demo-app
kubectl get namespace demo-app  # Should be gone
```

### Step 4: Restore from backup
```bash
kubectl apply -f restores/restore-postgres-database.yaml
# Or use Velero CLI:
velero restore create --from-backup demo-backup
velero restore describe demo-backup-restore
# Verify the namespace and resources are back
kubectl get all -n demo-app
```

### Step 5: Review runbooks
Browse the `runbooks/` directory for operational procedures.

## âœ… Verification

| Check | Command | Expected |
|-------|---------|----------|
| Velero installed | `velero version` | Client and server versions |
| Backup created | `velero backup get` | Backup in Completed phase |
| Namespace deleted | `kubectl get ns demo-app` | Not found |
| Restore successful | `velero restore get` | Restore in Completed phase |
| Data recovered | `kubectl get all -n demo-app` | Original resources restored |

```bash
# Cleanup
kind delete cluster --name dr-lab
```

## 👨‍💻 Author

*Built to demonstrate Site Reliability Engineering, RTO/RPO validation, and stateful Kubernetes operations.*
