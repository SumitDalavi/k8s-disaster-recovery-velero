# Architecture: Kubernetes Disaster Recovery
> Maturity: Lab / Reference Implementation

## System Diagram
The following Mermaid.js sequence diagram maps the core workflow and interactions:

```mermaid
sequenceDiagram
    CronJob->>Velero: Trigger Backup
Velero->>K8sAPI: Snapshot Resources
Velero->>CSI: Snapshot Volumes
Velero->>S3: Upload Archive
```


## How Velero Works
Velero consists of two components:
1. **A command-line client (CLI)** that runs locally.
2. **A server deployment** running within the Kubernetes cluster.

When a backup is triggered, the Velero controller queries the Kubernetes API server for all objects (or filtered by namespace/label). It serializes these objects into JSON and uploads them to a configured object storage bucket (S3, Azure Blob, GCS).

Simultaneously, if `snapshotVolumes` is enabled, Velero communicates with the cloud provider's API (via plugins) to trigger underlying disk snapshots of the Persistent Volumes attached to the pods.

## Multi-Cluster Restore Strategy
Because Velero backs up Kubernetes API YAML rather than taking an `etcd` database snapshot, it is incredibly flexible. You can:
- Back up from an on-prem cluster and restore to AWS EKS.
- Back up from Kubernetes v1.28 and restore to v1.30 (in most cases).
- Restore a specific namespace to a different cluster for debugging.

This API-level backup makes it vastly superior to node-level or etcd-level backups in modern cloud-native architectures.

## Progressive Credential Loading & Production Architecture (v0.2.0)

This service implements the **Progressive Credential Loading (PCL)** pattern, decoupling development speed from external infrastructure provisioning:

```mermaid
graph LR
    Env[Environment Credentials] -->|Detect Keys & URLs| Detector[Credential Detector]
    Detector -->|No Credentials / Missing| Mock[Mock Mode Factory]
    Detector -->|Valid Credentials Present| Live[Live Provider Factory]
    Mock --> Runtime[Application Core & /health]
    Live --> Runtime
```

### Core Architecture Components
1. **Mode Detection Singleton:** Inspects environment configuration at boot time without hard crashes on missing secrets.
2. **Dual-Mode Factory Wrappers:**
   - **Storage / Cache:** In-process maps or SQLite `:memory:` transparently promote to managed Redis or PostgreSQL when connection strings are supplied.
   - **AI Providers:** Deterministic heuristic generators and local embeddings transparently promote to live OpenAI, Anthropic, or Gemini API clients.
3. **Hot-Reload & Dynamic TLS:** File watchers monitor mounted volume paths (Kubernetes ConfigMaps and Secrets) to update certificates and limit configs atomically without process restarts.
4. **Health & Observability:** The `/health` endpoint exposes real-time runtime mode metadata (`mock` vs `live`) across all backing adapters.
