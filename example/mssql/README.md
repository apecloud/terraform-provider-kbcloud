# MSSQL Terraform Examples - Operations Guide

This directory contains examples for managing Microsoft SQL Server clusters on KubeBlocks Cloud using Terraform.

## 📁 Directory Structure

```
mssql/
├── main.tf                      # Single parameterized cluster definition
├── variables.tf                 # All configurable parameters (generated from example)
├── variables.tf.example         # Configuration template
├── run.sh                       # Automated test script
├── RUN_SCRIPT_GUIDE.md          # Script usage guide
├── MULTI_MODE_GUIDE.md          # Multi-mode configuration guide
├── REFACTORING_SUMMARY.md       # Refactoring details
└── ops-examples/                # Operation example files (.tfvars)
    ├── README.md                # Operations guide
    ├── vscale-up-compute.tfvars
    ├── hscale-out.tfvars
    ├── reconfigure-params.tfvars
    ├── backup-modify.tfvars
    └── termination-protect.tfvars
```

## 🚀 Quick Start

### Method 1: Using run.sh (Recommended)

```bash
# View help
./run.sh --help

# Create cluster (Always On AG with 3 replicas)
./run.sh -t 1 -cn "my-mssql" -r 3 -s 50

# Scale up compute
./run.sh -t 4 -cc "mssql.cluster.mssql.2c4g.general"

# Scale out replicas
./run.sh -t 5 -r 5

# Enable backups
./run.sh -t 7 -ab true -bm "full" -bs "0 2 * * *"

# Destroy cluster
./run.sh -t 2
```

See [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md) for complete documentation.

### Method 2: Using terraform.tfvars

```bash
# Copy and edit configuration
cp variables.tf.example variables.tf
vim variables.tf

# Initialize and apply
terraform init
terraform apply -var-file=variables.tf
```

## 🔧 Operations Guide

All operations use the **layered tfvars** approach:

### 1. Vertical Scaling (VScale)

Scale CPU, Memory, or Storage.

**Using run.sh:**
```bash
./run.sh -t 4 -cc "mssql.cluster.mssql.2c4g.general"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=variables.tf \
  -var-file=ops-examples/vscale-up-compute.tfvars
```

**What changes:** Instance class from `1c2g` to `2c4g` (1 CPU/2GB → 2 CPU/4GB).

See [ops-examples/README.md](ops-examples/README.md#1-vertical-scaling-vscale) for more details.

---

### 2. Horizontal Scaling (HScale)

Add or remove replicas for Always On AG.

**Using run.sh:**
```bash
./run.sh -t 5 -r 5
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=variables.tf \
  -var-file=ops-examples/hscale-out.tfvars
```

**What changes:** Replicas from 3 to 5 (better fault tolerance).

⚠️ **Note**: MSSQL HScale is currently limited. See [MSSQL Engine Limitations](../../docs/resources/cluster.md) for details.

See [ops-examples/README.md](ops-examples/README.md#2-horizontal-scaling-hscale) for more details.

---

### 3. Parameter Reconfiguration

Modify database parameters.

**Using run.sh:**
```bash
./run.sh -t 6 -cp '{"productEdition": "Enterprise"}'
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=variables.tf \
  -var-file=ops-examples/reconfigure-params.tfvars
```

**What changes:** Updates MSSQL configuration like product edition, collation, etc.

See [ops-examples/README.md](ops-examples/README.md#3-parameter-reconfiguration) for more details.

---

### 4. Backup Configuration

Configure automatic backups with full/transaction log backups.

**Using run.sh:**
```bash
./run.sh -t 7 -ab true -bm "full" -bs "0 2 * * *" -rp "7d"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=variables.tf \
  -var-file=ops-examples/backup-modify.tfvars
```

**What changes:** Enables daily full backups at 2:00 AM with PITR support.

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
  -var-file=variables.tf \
  -var-file=ops-examples/termination-protect.tfvars
```

**What changes:** Policy from `Delete` to `DoNotTerminate`.

See [ops-examples/README.md](ops-examples/README.md#5-termination-policy) for more details.

## 💡 Common Workflows

### Workflow 1: Production Deployment (Always On AG)

```bash
# 1. Create production cluster with Enterprise edition
./run.sh -t 1 -cn "mssql-prod" -env "prod" -r 3 -s 100 \
  -cc "mssql.cluster.mssql.4c8g.general" -tp "DoNotTerminate"

# 2. Enable backups with PITR
./run.sh -t 7 -ab true -bm "full" -bs "0 2 * * *" -rp "7d"
```

### Workflow 2: Development Environment

```bash
# 1. Create dev cluster
./run.sh -t 1 -cn "mssql-dev" -env "dev" -r 3 -s 20

# 2. Test operations
./run.sh -t 4 -cc "mssql.cluster.mssql.2c4g.general"
./run.sh -t 5 -r 5

# 3. Clean up
./run.sh -t 2
```

## 🗄️ MSSQL-Specific Features

### Cluster Mode (Always On Availability Group)

MSSQL uses Always On AG for high availability:
```hcl
mode = "cluster"
replicas = 3  # Minimum for Always On AG
```

### Extra Configuration Options

#### Product Edition
```hcl
extra = {
  productEdition = "Enterprise"  # or "Standard"
}
```

#### Collation Settings
```hcl
extra = {
  collation = "Chinese_PRC_CI_AS"  # Case-insensitive, accent-sensitive
}
```

Common collations:
- `SQL_Latin1_General_CP1_CI_AS`: Default English
- `Chinese_PRC_CI_AS`: Chinese support
- `Japanese_CI_AS`: Japanese support

#### Default Database
```hcl
extra = {
  defaultDBName = "db1"
}
```

#### Certificate Configuration
```hcl
extra = {
  certificate = {
    custom = false  # Use default certificate
  }
}
```

### Backup Methods

- **full**: Full database backup
- **transaction-log**: Transaction log backup for PITR
- Supports point-in-time recovery

### IOPS Configuration

MSSQL benefits from high IOPS:
```hcl
read_iops  = 2000  # Read IOPS limit
write_iops = 2000  # Write IOPS limit
```


## ⚠️ Important Notes

- **Replica Count**: Minimum 3 for Always On AG with automatic failover
- **Product Edition**: Enterprise edition required for advanced features
- **Collation**: Choose appropriate collation for your language requirements
- **Certificates**: Enable custom certificates for production security
- **Backup Strategy**: Combine full + transaction log backups for PITR
- **Storage Performance**: MSSQL is I/O intensive, use high IOPS storage
- **Termination Policy**: Set to "DoNotTerminate" for production clusters
- **License**: Ensure you have appropriate SQL Server licenses
- **HScale Limitation**: MSSQL horizontal scaling has limitations. Check documentation.
- **Preview First**: Always use `./run.sh -t 3` or `terraform plan` before applying changes

## 📚 Additional Resources

- [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md) - Complete run.sh documentation
- [MULTI_MODE_GUIDE.md](MULTI_MODE_GUIDE.md) - Multi-mode configuration guide
- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Refactoring details
- [ops-examples/README.md](ops-examples/README.md) - Detailed operations guide
- [KubeBlocks Documentation](https://kubeblocks.io/docs)
