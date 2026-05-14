# PostgreSQL Terraform Examples - Operations Guide

This directory contains examples for managing PostgreSQL clusters on KubeBlocks Cloud using Terraform.

## 📁 Directory Structure

```
postgresql/
├── main.tf                      # Single parameterized cluster definition
├── variables.tf                 # All configurable parameters
├── terraform.tfvars.example     # Configuration template
├── run.sh                       # Automated test script
├── RUN_SCRIPT_GUIDE.md          # Script usage guide
├── REFACTORING_SUMMARY.md       # Refactoring details
└── ops-examples/                # Operation example files (.tfvars)
    ├── README.md                # Operations guide
    ├── vscale-up-compute.tfvars
    ├── hscale-out.tfvars
    ├── reconfigure-params.tfvars
    ├── backup-modify.tfvars
    ├── volume-expand-operation.tfvars
    └── termination-protect.tfvars
```

## 🚀 Quick Start

### Method 1: Using run.sh (Recommended)

```bash
# View help
./run.sh --help

# Create cluster
./run.sh -t 1 -cn "my-postgres" -r 2 -s 50

# Scale up compute
./run.sh -t 4 -cc "postgresql.replication.postgresql.2c4g.general"

# Scale out replicas
./run.sh -t 5 -r 3

# Enable backups with WAL-G
./run.sh -t 7 -ab true -bm "wal-g-archive" -bs "0 2 * * *"

# Destroy cluster
./run.sh -t 2
```

See [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md) for complete documentation.

### Method 2: Using terraform.tfvars

```bash
# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Initialize and apply
terraform init
terraform apply -var-file=terraform.tfvars
```

## 🔧 Operations Guide

All operations use the **layered tfvars** approach:

### 1. Vertical Scaling (VScale)

Scale CPU, Memory, or Storage.

**Using run.sh:**
```bash
./run.sh -t 4 -cc "postgresql.replication.postgresql.2c4g.general"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/vscale-up-compute.tfvars
```

**What changes:** Instance class from `1c2g` to `2c4g` (1 CPU/2GB → 2 CPU/4GB).

See [ops-examples/README.md](ops-examples/README.md#1-vertical-scaling-vscale) for more details.

---

### 2. Horizontal Scaling (HScale)

Add or remove replicas.

**Using run.sh:**
```bash
./run.sh -t 5 -r 3
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/hscale-out.tfvars
```

**What changes:** Replicas from 2 to 3.

See [ops-examples/README.md](ops-examples/README.md#2-horizontal-scaling-hscale) for more details.

---

### 3. Parameter Reconfiguration

Modify database parameters.

**Using run.sh:**
```bash
./run.sh -t 6 -cp '{"max_connections": "500"}'
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/reconfigure-params.tfvars
```

**What changes:** Updates PostgreSQL configuration parameters like max_connections, shared_buffers, etc.

See [ops-examples/README.md](ops-examples/README.md#3-parameter-reconfiguration) for more details.

---

### 4. Backup Configuration

Configure automatic backups with WAL-G and PITR.

**Using run.sh:**
```bash
./run.sh -t 7 -ab true -bm "wal-g-archive" -bs "0 2 * * *" -rp "7d"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/backup-modify.tfvars
```

**What changes:** Enables daily backups at 2:00 AM with WAL-G method and PITR support.

See [ops-examples/README.md](ops-examples/README.md#4-backup-operations) for more details.

---

### 5. Volume Expansion

Expand storage for existing volumes.

**Using run.sh:**
```bash
./run.sh -t 9 -s 100 -vct "data"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/volume-expand-operation.tfvars
```

**What changes:** Expands the specified PVC (e.g., data volume) from current size to 100 GB.

See [ops-examples/README.md](ops-examples/README.md#6-volume-expansion) for more details.

---

### 6. Termination Policy

Protect cluster from accidental deletion.

**Using run.sh:**
```bash
./run.sh -t 8 -tp "DoNotTerminate"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/termination-protect.tfvars
```

**What changes:** Policy from `Delete` to `DoNotTerminate`.

See [ops-examples/README.md](ops-examples/README.md#5-termination-policy) for more details.

## 💡 Common Workflows

### Workflow 1: Production Deployment

```bash
# 1. Create production cluster with WAL-G backup
./run.sh -t 1 -cn "pg-prod" -env "prod" -r 3 -s 100 \
  -cc "postgresql.replication.postgresql.4c8g.general" -tp "DoNotTerminate"

# 2. Enable WAL-G backups with PITR
./run.sh -t 7 -ab true -bm "wal-g-archive" -bs "0 2 * * *" -rp "7d"
```

### Workflow 2: Development Environment

```bash
# 1. Create dev cluster
./run.sh -t 1 -cn "pg-dev" -env "dev" -r 1 -s 10

# 2. Test operations
./run.sh -t 4 -cc "postgresql.replication.postgresql.2c4g.general"
./run.sh -t 5 -r 2

# 3. Clean up
./run.sh -t 2
```

## 🐘 PostgreSQL-Specific Features

### WAL-G Backup

PostgreSQL uses WAL-G for continuous archiving:
- `auto_backup_method = "wal-g"`: Physical backup using WAL-G
- `continuous_backup_method = "wal-g-archive"`: WAL archiving for PITR
- Supports point-in-time recovery
- Incremental backup support

### I/O Configuration

PostgreSQL supports IOPS limits for better performance:
```hcl
read_iops  = 2000  # Read IOPS limit
write_iops = 2000  # Write IOPS limit
```

### Multi-Volume Support

PostgreSQL clusters can use separate volumes:
- `data`: Main database files
- `wal`: Write-ahead logs (improves performance)

### High Availability

Recommended configurations:
- Minimum 2 replicas for basic HA
- 3 replicas for production with quorum
- Distribute across availability zones

## ⚠️ Important Notes

- **Storage Expansion Only**: You can increase storage but cannot decrease it
- **WAL Storage**: Consider separate WAL volume for better performance
- **Connection Limits**: Adjust max_connections based on your workload
- **Maintenance Window**: Changes may only apply during configured maintenance windows
- **Termination Policy**: Set to "DoNotTerminate" for production clusters
- **Preview First**: Always use `./run.sh -t 3` or `terraform plan` before applying changes

## 📚 Additional Resources

- [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md) - Complete run.sh documentation
- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Refactoring details
- [ops-examples/README.md](ops-examples/README.md) - Detailed operations guide
- [KubeBlocks Documentation](https://kubeblocks.io/docs)
