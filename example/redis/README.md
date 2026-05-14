# Redis Terraform Examples - Operations Guide

This directory contains examples for managing Redis clusters on KubeBlocks Cloud using Terraform, supporting multiple deployment modes.

## 📁 Directory Structure

```
redis/
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

# Create replication cluster (default)
./run.sh -t 1 -cn "my-redis" -r 2 -s 20

# Scale up compute
./run.sh -t 4 -cc "redis.replication.redis.2c2g.general"

# Scale out replicas
./run.sh -t 5 -r 3

# Enable backups
./run.sh -t 7 -ab true -bm "aof" -bs "0 2 * * *"

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
./run.sh -t 4 -cc "redis.replication.redis.2c2g.general"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/vscale-up-compute.tfvars
```

**What changes:** Instance class from `1c1g` to `2c2g` (1 CPU/1GB → 2 CPU/2GB).

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
./run.sh -t 6 -cp '{"maxmemory": "1gb"}'
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/reconfigure-params.tfvars
```

**What changes:** Updates Redis configuration parameters like maxmemory, timeout, etc.

See [ops-examples/README.md](ops-examples/README.md#3-parameter-reconfiguration) for more details.

---

### 4. Backup Configuration

Configure automatic backups with RDB/AOF.

**Using run.sh:**
```bash
./run.sh -t 7 -ab true -bm "aof" -bs "0 2 * * *" -rp "7d"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/backup-modify.tfvars
```

**What changes:** Enables daily backups at 2:00 AM with AOF method.

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

### Workflow 1: Production Deployment (Replication)

```bash
# 1. Create production cluster
./run.sh -t 1 -cn "redis-prod" -env "prod" -r 3 -s 50 \
  -cc "redis.replication.redis.4c8g.general" -tp "DoNotTerminate"

# 2. Enable backups
./run.sh -t 7 -ab true -bm "aof" -bs "0 2 * * *" -rp "7d"
```

### Workflow 2: Development Environment

```bash
# 1. Create dev cluster (standalone)
./run.sh -t 1 -cn "redis-dev" -env "dev" -r 1 -s 10

# 2. Test operations
./run.sh -t 4 -cc "redis.replication.redis.2c2g.general"
./run.sh -t 5 -r 2

# 3. Clean up
./run.sh -t 2
```

## 🔄 Redis-Specific Features

### Topology Modes

Redis supports multiple deployment modes. See [MULTI_MODE_GUIDE.md](MULTI_MODE_GUIDE.md) for detailed configuration.

#### Standalone Mode
```hcl
mode = "standalone"
replicas = 1
```

#### Replication Mode (Default)
```hcl
mode = "replication"
replicas = 2  # 1 master + 1 replica
```

#### Cluster Mode (Sharding)
```hcl
mode = "cluster"
comp_num = 3  # Number of shards
replicas = 2  # Replicas per shard
network_mode = "HeadlessService"
component_name = "redis-cluster"
```

#### Sentinel Mode
```hcl
mode = "sentinel"
replicas = 2  # Redis data nodes
sentinel_replicas = 3  # Sentinel nodes
network_mode = "HostNetwork"
```

### Backup Methods

- **RDB**: Point-in-time snapshot (faster restore)
- **AOF**: Append-only file (better durability, supports PITR)

### IOPS Configuration

Redis benefits from high IOPS:
```hcl
read_iops  = 2000  # Read IOPS limit
write_iops = 2000  # Write IOPS limit
```

### Network Modes

- **HeadlessService**: Direct pod access (required for Cluster mode)
- **HostNetwork**: Host-level networking (recommended for Sentinel mode)


## ⚠️ Important Notes

- **Cluster Mode**: Data redistribution occurs when changing shard count
- **Sentinel Quorum**: Use odd number of sentinels (3, 5, 7)
- **Memory Limits**: Ensure class_code provides adequate memory for your dataset
- **Persistence**: Enable AOF for better durability in production
- **Network Mode**: Choose based on your Kubernetes network plugin
- **Termination Policy**: Set to "DoNotTerminate" for production clusters
- **Preview First**: Always use `./run.sh -t 3` or `terraform plan` before applying changes

## 📚 Additional Resources

- [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md) - Complete run.sh documentation
- [MULTI_MODE_GUIDE.md](MULTI_MODE_GUIDE.md) - Multi-mode configuration guide
- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Refactoring details
- [ops-examples/README.md](ops-examples/README.md) - Detailed operations guide
- [KubeBlocks Documentation](https://kubeblocks.io/docs)
