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

## ADR-002: Progressive Credential Loading (PCL) Architecture
- **Context:** Production hardening required live backends (PostgreSQL, Redis, OpenAI, Anthropic), but removing mocks would break CI pipelines and create high developer onboarding friction.
- **Decision:** Implement Progressive Credential Loading. Keep in-memory and local mock heuristics as the default safe baseline, while wrapping external integrations in auto-promoting factory adapters triggered by environment variables.
- **Consequences:** 
  - *Pros:* 100% CI pass rate without requiring external secrets; zero setup friction for new contributors; progressive upgrade to production clusters.
  - *Cons:* Adds lightweight factory abstraction layers and runtime credential detection logic.
