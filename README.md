# Kubernetes Disaster Recovery & Chaos Lab 🌋💾

[![CI Pipeline](https://github.com/SumitDalavi/k8s-disaster-recovery-velero/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/SumitDalavi/k8s-disaster-recovery-velero/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/SumitDalavi/k8s-disaster-recovery-velero?color=0969da&label=release&logo=github)](https://github.com/SumitDalavi/k8s-disaster-recovery-velero/releases)
[![Release Workflow](https://github.com/SumitDalavi/k8s-disaster-recovery-velero/actions/workflows/release.yml/badge.svg)](https://github.com/SumitDalavi/k8s-disaster-recovery-velero/actions/workflows/release.yml)
[![GHCR Container](https://img.shields.io/badge/ghcr.io-v0.2.0-blue?logo=docker&logoColor=white)](https://github.com/SumitDalavi/k8s-disaster-recovery-velero/pkgs/container/k8s-disaster-recovery-velero)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://www.python.org)
[![SBOM](https://img.shields.io/badge/SBOM-SPDX%202.3-blueviolet?logo=spdx)](https://github.com/SumitDalavi/k8s-disaster-recovery-velero/releases/tag/v0.2.0)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

> A comprehensive Disaster Recovery architecture for Kubernetes using Velero, demonstrating RTO/RPO measurement, simulated cluster loss, and automated recovery runbooks.

## The Problem

Most teams claim to "do backups" because their cloud provider snapshots VMs. But in Kubernetes, cluster state is defined by hundreds of API objects (Deployments, Secrets, CRDs) combined with stateful Persistent Volumes. If a cluster is deleted or completely corrupted, restoring VM snapshots is insufficient. You need a way to restore the *Kubernetes State* and the *Data* to a brand new, empty cluster.

## The Solution

This project implements **Velero** as the core Disaster Recovery engine. 

1. **Backup Schedules**: Velero continuously backs up Kubernetes API objects to an Azure Blob Storage / AWS S3 bucket.
2. **Volume Snapshots**: Velero integrates with CSI drivers to snapshot Persistent Volumes (e.g., PostgreSQL databases) synchronously with the API objects.
3. **Recovery Runbooks**: Documented, tested procedures for standing up a new cluster and restoring the state from the backup bucket, achieving a tested RTO (typically under 5 minutes for namespace-level restores in test environments) (Recovery Time Objective).

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

## 📋 Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | >= 1.28 | Kubernetes CLI |
| [kind](https://kind.sigs.k8s.io/) or [minikube](https://minikube.sigs.k8s.io/) | Latest | Local K8s cluster |
| [Velero CLI](https://velero.io/docs/main/basic-install/) | >= 1.12 | Backup/restore CLI |
| [Helm](https://helm.sh/) | >= 3.x | Package manager |
| [MinIO](https://min.io/) (optional) | Latest | Local S3-compatible storage for backups |

## 🚀 Step-by-Step Setup

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

## 🧪 Usage & Demo â€” Backup & Disaster Recovery

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

## ✅ Verification

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

## 🚀 Progressive Credential Loading & Execution Tiers

This project implements **Progressive Credential Loading (PCL)**, allowing it to run immediately out-of-the-box without external dependencies while seamlessly upgrading as credentials are provided.

### Tier 1: Zero-Config Mock Mode (Default)
Ideal for CI, testing, and rapid local evaluation.
- **Execution:** Run with default configuration (`cp .env.example .env`). Zero API keys, databases, or cloud credentials required.
- **Fallback Behavior:** In-memory caches, deterministic offline heuristics, mock vector embeddings, and local mock storage are automatically used.
- **Health Verification:** Endpoints report `{"mode": "mock"}` for unconfigured dependencies.

### Tier 2: Local Development with Live Services
Connect specific external services while keeping others mocked.
- **Execution:** Provide credentials in `.env` for the services you want active (e.g., `BACKUP_BUCKET, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY`).
- **Progressive Upgrade:** The runtime inspects environment variables on boot and dynamically promotes only configured modules to live mode.
- **Safe Fallback:** Any missing credentials automatically remain on mock fallbacks with no crashes or missing service errors.

### Tier 3: Production Hardened
Enterprise deployment with production-grade backends, security scans, and container distributions.
- **OCI Container Image:** Pre-built, multi-arch image on GitHub Container Registry:
  ```bash
  docker pull ghcr.io/sumitdalavi/k8s-disaster-recovery-velero:v0.2.0
  ```
- **Production Orchestration:** Mount secrets via Kubernetes Secrets or cloud secret managers with atomic config reload support.
- **Release Verification:** Checksums and SPDX SBOM available on [GitHub Releases](https://github.com/SumitDalavi/k8s-disaster-recovery-velero/releases).

## 📚 Documentation

- [Architecture](docs/ARCHITECTURE.md) — System diagram and component details
- [RTO/RPO Drill Results](docs/rto_rpo_drill_results.md) — Measured performance metrics
- [Runbook](docs/runbook.md) — Setup, commands, and expected outputs
- [Decisions](docs/decisions.md) — ADRs for DR implementation
- [Changelog](docs/changelog.md) — Change history

## Mock Boundaries (Honest Scope)

| What | Status | Details |
|---|---|---|
| Velero Engine | **Real** | Velero is installed and executing real backup/restore commands. |
| Object Storage | **Simulated** | Using local `MinIO` instead of AWS S3 / Azure Blob Storage to avoid cloud costs. |
| Volume Snapshots | **Simulated** | Demonstrating API backups; CSI Volume Snapshots require cloud-specific storage classes not present in standard `kind`. |

## 🔗 Related Projects

- [`chaos-slo-gameday`](../chaos-slo-gameday/) — Chaos engineering principles that complement DR drills.

## 🔒 Release & Security Verification

Every tagged release (`v*.*.*`) triggers an automated DevSecOps release workflow:
1. **Automated Testing:** Runs pytest validation suite across backup and restore routines.
2. **Container Image Build:** Builds production container image (`ghcr.io/sumitdalavi/k8s-disaster-recovery-velero:<tag>`).
3. **Vulnerability Scanning:** Scans the image using [Aqua Security Trivy](https://github.com/aquasecurity/trivy-action) for `HIGH` and `CRITICAL` CVEs.
4. **SBOM Generation:** Generates a Software Bill of Materials (SBOM) in SPDX JSON format (`sbom.spdx.json`) using [Anchore Syft](https://github.com/anchore/sbom-action).
5. **GitHub Release Publishing:** Packages release notes and attaches `sbom.spdx.json` as a verifiable supply-chain asset.

### Verifying Releases via GitHub CLI
```bash
# View release details
gh release view v0.2.0 --repo SumitDalavi/k8s-disaster-recovery-velero

# Download and verify SBOM
gh release download v0.2.0 --repo SumitDalavi/k8s-disaster-recovery-velero --pattern "sbom.spdx.json"
cat sbom.spdx.json | jq .
```

## 👨‍💻 Author

**Sumit Dalavi** — Senior DevSecOps / Platform Engineer
[GitHub](https://github.com/SumitDalavi) | [LinkedIn](https://in.linkedin.com/in/sumit-dalavi-762838129)

---
*Built with a focus on robust patterns, not toy demos.*
