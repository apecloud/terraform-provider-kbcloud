# MongoDB Terraform Examples - Operations Guide

This directory contains examples for managing MongoDB clusters on KubeBlocks Cloud using Terraform, supporting multiple topology modes.

## 📁 Directory Structure

```
mongodb/
├── main.tf                      # Single parameterized cluster definition
├── variables.tf                 # All configurable parameters
├── terraform.tfvars.example     # Configuration template
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

# Create replicaset cluster (default)
./run.sh -t 1 -cn "my-mongodb" -r 3 -s 50

# Scale up compute
./run.sh -t 4 -cc "mongodb.replicaset.mongodb.2c4g.general"

# Scale out replicas
./run.sh -t 5 -r 5

# Enable backups with PBM
./run.sh -t 7 -ab true -bm "pbm-physical" -bs "0 2 * * *"

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
./run.sh -t 4 -cc "mongodb.replicaset.mongodb.2c4g.general"
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
./run.sh -t 5 -r 5
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/hscale-out.tfvars
```

**What changes:** Replicas from 3 to 5 (better fault tolerance).

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

**What changes:** Updates MongoDB configuration parameters.

See [ops-examples/README.md](ops-examples/README.md#3-parameter-reconfiguration) for more details.

---

### 4. Backup Configuration

Configure automatic backups with PBM.

**Using run.sh:**
```bash
./run.sh -t 7 -ab true -bm "pbm-physical" -bs "0 2 * * *" -rp "7d"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/backup-modify.tfvars
```

**What changes:** Enables daily physical backups at 2:00 AM with PBM.

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

### Workflow 1: Production Deployment (Replicaset)

```bash
# 1. Create production cluster
./run.sh -t 1 -cn "mongo-prod" -env "prod" -r 3 -s 100 \
  -cc "mongodb.replicaset.mongodb.4c8g.general" -tp "DoNotTerminate"

# 2. Enable backups with PBM
./run.sh -t 7 -ab true -bm "pbm-physical" -bs "0 2 * * *" -rp "7d"
```

### Workflow 2: Development Environment

```bash
# 1. Create dev cluster (standalone)
./run.sh -t 1 -cn "mongo-dev" -env "dev" -r 1 -s 10

# 2. Test operations
./run.sh -t 4 -cc "mongodb.replicaset.mongodb.2c4g.general"
./run.sh -t 5 -r 3

# 3. Clean up
./run.sh -t 2
```

## 🍃 MongoDB-Specific Features

### Topology Modes

MongoDB supports multiple topology modes. See [MULTI_MODE_GUIDE.md](MULTI_MODE_GUIDE.md) for detailed configuration.

#### Standalone Mode
```hcl
mode = "standalone"
replicas = 1
```

#### Replicaset Mode (Recommended for Production)
```hcl
mode = "replicaset"
replicas = 3  # Minimum for HA with quorum
```

#### Sharding Mode (Horizontal Scaling)
```hcl
mode = "sharding"
shard_comp_num = 2      # Number of shards
shard_replicas = 3      # Replicas per shard
config_replicas = 3     # Config servers (odd number)
mongos_replicas = 2     # Query routers
```

### Component Types in Sharding

- **mongo-shard**: Stores actual data (can have multiple shards)
- **mongo-config-server**: Stores metadata (always 3 replicas)
- **mongo-mongos**: Query routers (scales horizontally)

### Backup Methods

- **pbm-physical**: Fast physical backup using PBM
- **pbm-pitr**: Point-in-time recovery with continuous backup

### IOPS Configuration

All MongoDB components benefit from high IOPS:
```hcl
read_iops  = 1000  # Read IOPS limit
write_iops = 1000  # Write IOPS limit
```


## ⚠️ Important Notes

- **Replica Count**: Always use odd numbers (3, 5, 7) for proper election
- **Config Servers**: Must always be 3 replicas in sharding mode
- **Shard Scaling**: Adding shards redistributes data automatically
- **Mongos Scaling**: Stateless, can scale freely based on load
- **Backup with PBM**: Requires PBM agent configuration
- **Termination Policy**: Set to "DoNotTerminate" for production clusters
- **Parameter Templates**: Each component type needs its own template
- **Preview First**: Always use `./run.sh -t 3` or `terraform plan` before applying changes

## 📚 Additional Resources

- [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md) - Complete run.sh documentation
- [MULTI_MODE_GUIDE.md](MULTI_MODE_GUIDE.md) - Multi-mode configuration guide
- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Refactoring details
- [ops-examples/README.md](ops-examples/README.md) - Detailed operations guide
- [KubeBlocks Documentation](https://kubeblocks.io/docs)
