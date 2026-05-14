# Kafka Terraform Test Script Guide

## 📖 Overview

The `run.sh` script provides a command-line interface for managing Kafka clusters on KubeBlocks Cloud using Terraform. It simplifies cluster operations by allowing you to configure and execute Terraform commands through simple command-line parameters.

---

## 🚀 Quick Start

### Prerequisites

1. **Terraform installed** (version >= 1.0)
2. **KubeBlocks Cloud account** with API credentials
3. **Bash shell** (macOS or Linux)

### Basic Usage

```bash
# Make script executable (if needed)
chmod +x run.sh

# View help
./run.sh --help

# Create a default Kafka cluster
./run.sh -t 1

# Destroy the cluster
./run.sh -t 2
```

---

## 📋 Command Reference

### Operation Types (`-t`)

| Type | Operation | Description |
|------|-----------|-------------|
| `1` | Init & Apply | Initialize Terraform and create cluster |
| `2` | Destroy | Delete the cluster |
| `3` | Plan | Preview changes without applying |
| `4` | VScale | Vertical scaling (CPU/Memory/Storage) |
| `5` | HScale | Horizontal scaling (replicas) |
| `6` | Reconfigure | Modify database parameters |
| `7` | Backup | Configure backup settings |
| `8` | Termination | Change termination policy |

---

## 🔧 Configuration Parameters

### Cluster Identity

| Parameter | Short | Long | Default | Description |
|-----------|-------|------|---------|-------------|
| Cluster Name | `-cn` | `--cluster-name` | `my-kafka` | Unique cluster identifier |
| Engine | `-e` | `--engine` | `kafka` | Database engine type |
| Version | `-v` | `--version` | `3.9.0` | Engine version |
| Mode | `-m` | `--mode` | `combined` | Deployment mode (combined/separated) |
| Environment | `-env` | `--environment` | `prod` | Environment name (dev/staging/prod) |

### Resource Configuration

| Parameter | Short | Long | Default | Description |
|-----------|-------|------|---------|-------------|
| Replicas | `-r` | `--replicas` | `2` | Number of replicas |
| Storage Size | `-s` | `--storage-size` | `20` | Storage size in GB |
| Class Code | `-cc` | `--class-code` | `kafka.combined.kafka-combine.1c1g.general` | Instance specification |

### Advanced Options

| Parameter | Short | Long | Default | Description |
|-----------|-------|------|---------|-------------|
| Termination Policy | `-tp` | `--termination-policy` | `Delete` | Delete or DoNotTerminate |
| Auto Backup | `-ab` | `--auto-backup` | `false` | Enable automatic backup |
| Backup Method | `-bm` | `--backup-method` | - | Backup method (topics) |
| Backup Schedule | `-bs` | `--backup-schedule` | - | Cron expression for backup schedule |
| Retention Policy | `-rp` | `--retention-policy` | `LastOne` | Backup retention policy |
| Custom Params | `-cp` | `--custom-params` | - | Custom parameters (JSON format) |
| Param Template | `-ptn` | `--param-template` | - | Parameter template name |
| Config File Name | `-cfn` | `--config-file-name` | - | Configuration file name for reconfigure (e.g., server.properties) |
| Component | `-comp` | `--component` | - | Component name for reconfigure (if empty, uses first component) |

### API Credentials

| Parameter | Long | Required | Description |
|-----------|------|----------|-------------|
| API URL | `-api-url` | No | KubeBlocks Cloud API endpoint |
| API Key | `-api-key` | Yes* | API authentication key |
| API Secret | `-api-secret` | Yes* | API authentication secret |
| Admin API Key | `-admin-api-key` | Yes* | Admin API key |
| Admin API Secret | `-admin-api-secret` | Yes* | Admin API secret |

*\*Required for actual operations, but can be set in terraform.tfvars*

---

## 💡 Usage Examples

### 1. Create a Development Cluster

```bash
./run.sh -t 1 \
    -cn "kafka-dev" \
    -env "dev" \
    -r 1 \
    -s 10 \
    -cc "kafka.combined.kafka-combine.1c1g.general"
```

**What this does:**
- Creates a single-replica Kafka cluster (combined mode)
- 10GB storage for data and metadata
- Minimal resources for development
- Named "kafka-dev"

---

### 2. Create a Production Cluster

```bash
./run.sh -t 1 \
    -cn "kafka-prod" \
    -env "prod" \
    -r 3 \
    -s 100 \
    -cc "kafka.separated.kafka-broker.4c8g.general" \
    -tp "DoNotTerminate"
```

**What this does:**
- Creates a 3-replica high-availability cluster (separated mode)
- 100GB storage
- Performance-optimized instance (4 CPU, 8GB RAM)
- Protected from accidental deletion

---

### 3. Scale Up Compute Resources

```bash
./run.sh -t 4 \
    -cc "kafka.combined.kafka-combine.2c4g.general"
```

**What this does:**
- Scales existing cluster to 2 CPU, 4GB RAM
- Triggers a vertical scaling operation
- May cause brief downtime during scaling

---

### 4. Scale Out Replicas

```bash
./run.sh -t 5 \
    -r 5
```

**What this does:**
- Increases replicas from current count to 5
- Adds more read replicas for better read performance
- No downtime required

---

### 5. Enable Automatic Backups

```bash
./run.sh -t 7 \
    -ab true \
    -bm "topics" \
    -bs "0 2 * * *" \
    -rp "7d"
```

**What this does:**
- Enables daily topic backups at 2:00 AM
- Uses topics backup method for Kafka
- Retains backups for 7 days

---

### 6. Modify Kafka Parameters

```bash
./run.sh -t 6 \
    -cp '{"sasl_enable": "true", "num.partitions": "6"}'
```

**What this does:**
- Updates Kafka configuration parameters
- Enables SASL authentication
- Sets default number of partitions to 6
- Applies changes dynamically (if supported)

---

### 7. Protect Cluster from Deletion

```bash
./run.sh -t 8 \
    -tp "DoNotTerminate"
```

**What this does:**
- Changes termination policy to prevent accidental deletion
- Must change back to "Delete" before destroying cluster

---

### 8. Preview Changes Before Applying

```bash
./run.sh -t 3
```

**What this does:**
- Runs `terraform plan` to show what will change
- No modifications are made
- Safe way to verify configuration

---

### 9. Destroy Cluster

```bash
./run.sh -t 2
```

**What this does:**
- Prompts for confirmation
- Destroys all cluster resources
- **Warning: This action is irreversible!**

---

## 🔄 Common Workflows

### Workflow 1: Complete Lifecycle

```bash
# Step 1: Create cluster
./run.sh -t 1 \
    -cn "my-app-db" \
    -r 2 \
    -s 50

# Step 2: Scale up after load increases
./run.sh -t 4 \
    -cc "kafka.combined.kafka-combine.2c4g.general"

# Step 3: Add more replicas for read scaling
./run.sh -t 5 \
    -r 4

# Step 4: Enable backups
./run.sh -t 7 \
    -ab true \
    -bm "topics" \
    -bs "0 3 * * *"

# Step 5: When done, destroy
./run.sh -t 2
```

---

### Workflow 2: Testing Different Configurations

```bash
# Test small configuration
./run.sh -t 1 -cn "test-small" -r 1 -s 10 -cc "kafka.combined.kafka-combine.1c1g.general"
# ... run tests ...
./run.sh -t 2

# Test medium configuration
./run.sh -t 1 -cn "test-medium" -r 3 -s 50 -cc "kafka.separated.kafka-broker.2c4g.general"
# ... run tests ...
./run.sh -t 2

# Test large configuration
./run.sh -t 1 -cn "test-large" -r 3 -s 100 -cc "kafka.separated.kafka-broker.4c8g.general"
# ... run tests ...
./run.sh -t 2
```

---

### Workflow 3: CI/CD Integration

```bash
#!/bin/bash
# deploy.sh - Automated deployment script

set -e

CLUSTER_NAME="app-${BUILD_NUMBER}"
ENVIRONMENT="${DEPLOY_ENV:-staging}"

echo "Deploying Kafka cluster: $CLUSTER_NAME"

# Create cluster
./run.sh -t 1 \
    -cn "$CLUSTER_NAME" \
    -env "$ENVIRONMENT" \
    -r 2 \
    -s 50 \
    -api-key "$TF_API_KEY" \
    -api-secret "$TF_API_SECRET" \
    -admin-api-key "$TF_ADMIN_API_KEY" \
    -admin-api-secret "$TF_ADMIN_API_SECRET"

echo "Cluster $CLUSTER_NAME deployed successfully"

# Run your application tests here
# ...

# Cleanup (optional)
# ./run.sh -t 2
```

---

## ⚙️ Configuration File

The script automatically creates and manages `terraform.tfvars`:

### First Run
```bash
./run.sh -t 1
```

This creates `terraform.tfvars` from the template with your specified parameters.

### Manual Editing
You can also edit `terraform.tfvars` directly:

```hcl
# terraform.tfvars
cluster_name     = "my-kafka"
environment_name = "prod"
replicas         = 3
storage_size_gb  = 100
class_code       = "kafka.separated.kafka-broker.4c8g.general"

# API credentials (recommended to use environment variables)
api_key          = "your_api_key"
api_secret       = "your_api_secret"
admin_api_key    = "your_admin_api_key"
admin_api_secret = "your_admin_api_secret"
```

Then run operations without specifying parameters:
```bash
./run.sh -t 4  # Uses values from terraform.tfvars
```

---

## 🔐 Security Best Practices

### 1. Use Environment Variables for Secrets

```bash
export TF_API_KEY="your_api_key"
export TF_API_SECRET="your_api_secret"
export TF_ADMIN_API_KEY="your_admin_api_key"
export TF_ADMIN_API_SECRET="your_admin_api_secret"

./run.sh -t 1 \
    -api-key "$TF_API_KEY" \
    -api-secret "$TF_API_SECRET" \
    -admin-api-key "$TF_ADMIN_API_KEY" \
    -admin-api-secret "$TF_ADMIN_API_SECRET"
```

### 2. Never Commit Credentials

Add to `.gitignore`:
```gitignore
terraform.tfvars
*.tfstate
*.tfstate.backup
```

### 3. Use Separate Credentials per Environment

```bash
# Development
./run.sh -t 1 -cn "dev-db" -env "dev" -api-key "$DEV_API_KEY" ...

# Production
./run.sh -t 1 -cn "prod-db" -env "prod" -api-key "$PROD_API_KEY" ...
```

---

## ❓ Troubleshooting

### Issue: "terraform.tfvars not found"

**Solution:**
```bash
# Create cluster first
./run.sh -t 1

# Or manually copy template
cp terraform.tfvars.example terraform.tfvars
```

---

### Issue: "Authentication failed"

**Solution:**
1. Verify API credentials are correct
2. Check if credentials have expired
3. Ensure you're using the right API endpoint

```bash
./run.sh -t 1 \
    -api-url "https://your-api-endpoint.com/api" \
    -api-key "correct_key" \
    -api-secret "correct_secret"
```

---

### Issue: "Class code not found"

**Solution:**
Verify available class codes in your environment:

```bash
kubectl get componentversions -A
```

Then use a valid class code:
```bash
./run.sh -t 1 -cc "valid.class.code.here"
```

---

### Issue: "Insufficient permissions"

**Solution:**
Ensure your API credentials have sufficient permissions:
- Cluster creation/modification
- Resource quota availability
- Namespace access

---

## 📊 Monitoring Operations

### Check Cluster Status

```bash
# Via kubectl
kubectl get clusters -n kubeblocks-cloud-ns

# Check OpsRequest status (for scaling/reconfig operations)
kubectl get opsrequest -n kubeblocks-cloud-ns
kubectl describe opsrequest <ops-name> -n kubeblocks-cloud-ns
```

### View Terraform State

```bash
terraform show
terraform state list
```

---

## 🎯 Tips and Tricks

### 1. Dry Run Before Applying

Always use `-t 3` (plan) before making changes:

```bash
./run.sh -t 3  # Preview changes
./run.sh -t 4 -cc "..."  # Apply if satisfied
```

### 2. Combine Multiple Operations

Create a custom tfvars file for complex changes:

```bash
cat > custom-ops.tfvars << EOF
class_code = "kafka.separated.kafka-broker.4c8g.general"
replicas = 3
auto_backup        = true
cron_expression    = "0 2 * * *"
EOF

terraform apply -var-file=terraform.tfvars -var-file=custom-ops.tfvars
```

### 3. Use Shell History for Frequent Operations

```bash
# Save common commands as shell functions
alias kafka-create='./run.sh -t 1 -cn "my-kafka" -r 3 -s 50'
alias kafka-scale='./run.sh -t 4 -cc "kafka.combined.kafka-combine.2c4g.general"'
alias kafka-destroy='./run.sh -t 2'
```

### 4. Backup terraform.tfvars

```bash
cp terraform.tfvars terraform.tfvars.backup.$(date +%Y%m%d)
```

---

## 📚 Additional Resources

- [Kafka Example README](README.md)
- [Operations Examples](ops-examples/README.md)
- [Migration Guide](MIGRATION_GUIDE.md)
- [KubeBlocks Documentation](https://kubeblocks.io/docs)
- [Terraform Documentation](https://developer.hashicorp.com/terraform)

---

## 🆘 Getting Help

### Display Help Message

```bash
./run.sh --help
```

### Check Script Version

```bash
head -20 run.sh | grep "Version\|Date"
```

### Debug Mode

Add `-x` flag to bash for detailed execution trace:

```bash
bash -x ./run.sh -t 1
```

---

## 📝 Changelog

### v1.0.0 (Current)
- Initial release
- Support for all major operations (create, destroy, scale, reconfigure, backup)
- Cross-platform support (macOS and Linux)
- Interactive confirmation for destructive operations
- Comprehensive help documentation

---

## 🤝 Contributing

Found a bug or have a feature request? Please:
1. Check existing issues
2. Create a new issue with detailed description
3. Submit a pull request if you have a fix

---

## 📄 License

This script is part of the terraform-provider-kbcloud project. See the main project license for details.
