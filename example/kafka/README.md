# Kafka Terraform Examples - Operations Guide

This directory contains examples for managing Kafka clusters on KubeBlocks Cloud using Terraform, supporting multiple deployment modes.

## 📁 Directory Structure

```
kafka/
├── main.tf                      # Single parameterized cluster definition
├── variables.tf                 # All configurable parameters
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

# Create combined mode cluster (default)
./run.sh -t 1 -cn "my-kafka" -r 3 -s 50

# Scale up compute
./run.sh -t 4 -cc "kafka.combined.kafka-combine.2c4g.general"

# Scale out replicas
./run.sh -t 5 -r 5

# Enable backups
./run.sh -t 7 -ab true -bm "topics" -bs "0 2 * * *"

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
./run.sh -t 4 -cc "kafka.combined.kafka-combine.2c4g.general"
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

Add or remove replicas/brokers.

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

**What changes:** Replicas from 3 to 5 (higher throughput).

See [ops-examples/README.md](ops-examples/README.md#2-horizontal-scaling-hscale) for more details.

---

### 3. Parameter Reconfiguration

Modify database parameters.

**Using run.sh:**
```bash
./run.sh -t 6 -cp '{"sasl_enable": "true"}'
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=variables.tf \
  -var-file=ops-examples/reconfigure-params.tfvars
```

**What changes:** Updates Kafka configuration like SASL authentication, topic settings, etc.

See [ops-examples/README.md](ops-examples/README.md#3-parameter-reconfiguration) for more details.

---

### 4. Backup Configuration

Configure automatic topic backups.

**Using run.sh:**
```bash
./run.sh -t 7 -ab true -bm "topics" -bs "0 2 * * *" -rp "7d"
```

**Using tfvars overlay:**
```bash
terraform apply \
  -var-file=variables.tf \
  -var-file=ops-examples/backup-modify.tfvars
```

**What changes:** Enables daily topic backups at 2:00 AM.

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

### Workflow 1: Production Deployment (Separated Mode)

```bash
# 1. Create production cluster with separated mode
./run.sh -t 1 -cn "kafka-prod" -env "prod" -r 3 -s 100 \
  -cc "kafka.separated.kafka-broker.4c8g.general" -tp "DoNotTerminate"

# 2. Enable backups
./run.sh -t 7 -ab true -bm "topics" -bs "0 2 * * *" -rp "7d"
```

### Workflow 2: Development Environment (Combined Mode)

```bash
# 1. Create dev cluster (combined mode)
./run.sh -t 1 -cn "kafka-dev" -env "dev" -r 3 -s 20

# 2. Test operations
./run.sh -t 4 -cc "kafka.combined.kafka-combine.2c4g.general"
./run.sh -t 5 -r 5

# 3. Clean up
./run.sh -t 2
```

## 📨 Kafka-Specific Features

### Deployment Modes

Kafka supports multiple deployment modes. See [MULTI_MODE_GUIDE.md](MULTI_MODE_GUIDE.md) for detailed configuration.

#### Combined Mode (Simple Setup)
```hcl
mode = "combined"
replicas = 3  # Broker + Controller combined
component_name = "kafka-combine"
```
- Simpler architecture
- Good for development/testing
- Single component to manage

#### Separated Mode (Recommended for Production)
```hcl
mode = "separated"
replicas = 3  # Brokers
broker_replicas = 3
controller_replicas = 3
component_name = "kafka-broker"
controller_component_name = "kafka-controller"
```
- Better isolation
- Independent scaling
- Recommended for production

#### withZookeeper Mode (Legacy)
```hcl
mode = "withZookeeper-10"
zookeeper_cluster = "your-zookeeper-cluster"
replicas = 5
component_name = "kafka-broker"
```
- Requires external ZooKeeper cluster
- Legacy deployment模式
- Use zookeeper_cluster to link ZooKeeper

### Multi-Volume Support

Kafka often uses separate volumes:
- **data**: Message logs (high IOPS needed)
- **metadata**: Controller metadata (in combined/separated modes)

```hcl
read_iops  = 1000  # Read IOPS limit
write_iops = 1000  # Write IOPS limit
```

### SASL Authentication

Enable SASL for security:
```hcl
extra = {
  sasl = {
    enable = true
  }
}
```

### Backup Methods

- **topics**: Backup topic data and configurations
- Schedule regular backups for disaster recovery

### Network Modes

- **HeadlessService**: Direct pod access (recommended)

### SASL Authentication
Enable SASL for security:
```hcl
extra = {
  sasl = {
    enable = true
  }
}
```

### Backup Methods
- **topics**: Backup topic data and configurations
- Schedule regular backups for disaster recovery


## ⚠️ Important Notes

- **Broker Count**: Minimum 3 for production HA
- **Controller Count**: Minimum 3 for quorum (odd number recommended)
- **Storage IOPS**: Kafka is I/O intensive, configure appropriate IOPS limits
- **Network Mode**: HeadlessService recommended for direct broker access
- **SASL Authentication**: Enable for production security
- **Topic Partitions**: Plan partition count based on expected throughput
- **Termination Policy**: Set to "DoNotTerminate" for production clusters
- **Backup Strategy**: Regular topic backups essential for disaster recovery
- **Preview First**: Always use `./run.sh -t 3` or `terraform plan` before applying changes

## 📚 Additional Resources

- [RUN_SCRIPT_GUIDE.md](RUN_SCRIPT_GUIDE.md) - Complete run.sh documentation
- [MULTI_MODE_GUIDE.md](MULTI_MODE_GUIDE.md) - Multi-mode configuration guide
- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Refactoring details
- [ops-examples/README.md](ops-examples/README.md) - Detailed operations guide
- [KubeBlocks Documentation](https://kubeblocks.io/docs)
