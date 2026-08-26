# Kubernetes Disaster Recovery Runbook

## Scenarios

### Scenario 1: Single Namespace Data Loss
```bash
# Find the most recent backup covering the namespace
velero backup get

# Restore specific namespace only
BACKUP_NAME=<backup-name> NAMESPACES=my-namespace bash scripts/restore.sh <backup-name>

# Verify
NAMESPACES=my-namespace bash scripts/verify-restore.sh
```

### Scenario 2: Full Cluster Loss
```bash
# 1. Provision new cluster
# 2. Install Velero pointing to same S3 bucket
# 3. Verify backup access
velero backup get

# 4. Restore all namespaces
bash scripts/restore.sh <latest-full-backup>

# 5. Verify
bash scripts/verify-restore.sh
```

### Scenario 3: Database Corruption
```bash
# Restore only the database namespace
NAMESPACES=databases bash scripts/restore.sh <backup-before-corruption>
```

## RTO / RPO Targets
| Metric | Target |
|--------|--------|
| RPO (Recovery Point Objective) | < 1 hour (hourly backup schedule) |
| RTO (Recovery Time Objective) | < 4 hours (full cluster restore) |

## Scheduled Backup Verification
Run monthly: `bash scripts/dr-test.sh`
