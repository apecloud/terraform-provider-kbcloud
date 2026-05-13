# KBCloud Terraform Provider - Examples Index

Welcome to the KBCloud Terraform Provider examples! This directory contains comprehensive, production-ready examples for deploying and managing database clusters on KubeBlocks Enterprise.

## 📚 Quick Navigation

### By Database Engine
- [MySQL](mysql/README.md) - Relational database with replication
- [PostgreSQL](postgresql/README.md) - Advanced relational database with WAL-G
- [Redis](redis/README.md) - In-memory data store (4 topology modes)
- [MongoDB](mongodb/README.md) - NoSQL document database (3 topology modes)
- [Kafka](kafka/README.md) - Distributed event streaming (3 deployment modes)
- [SQL Server](mssql/README.md) - Microsoft SQL Server with Always On AG

### By Operation Type

#### 🚀 Cluster Creation
All engines use the same pattern:
- [MySQL](mysql/main.tf)
- [PostgreSQL](postgresql/main.tf)
- [Redis](redis/main.tf) - Standalone, Replication, Sentinel, Cluster
- [MongoDB](mongodb/main.tf) - Standalone, Replicaset, Sharding
- [Kafka](kafka/main.tf) - Combined, Separated, withZookeeper
- [MSSQL](mssql/main.tf)

**Quick Start:**
```bash
cd mysql
./run.sh -t 1 -cn "my-cluster" -r 3 -s 50
```

#### 📈 Vertical Scaling (VScale)
Scale CPU, Memory, and Storage using tfvars overlays:
```bash
./run.sh -t 4 -cc "mysql.replication.mysql.2c4g.general"
# or
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars
```
- See [ops-examples/vscale-up-compute.tfvars](mysql/ops-examples/vscale-up-compute.tfvars)

#### ↔️ Horizontal Scaling (HScale)
Scale replicas and shards:
```bash
./run.sh -t 5 -r 5
# or
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/hscale-out.tfvars
```
- See [ops-examples/hscale-out.tfvars](mysql/ops-examples/hscale-out.tfvars)
- **Note**: MSSQL does not support HScale

#### ⚙️ Parameter Reconfiguration
Modify cluster parameters:
```bash
./run.sh -t 6 -cp '{"max_connections": "500"}'
# or
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-params.tfvars
```
- See [ops-examples/reconfigure-params.tfvars](mysql/ops-examples/reconfigure-params.tfvars)

#### 💾 Backup Operations
Configure and modify backup policies:
```bash
./run.sh -t 7 -ab true -bm "xtrabackup" -bs "0 2 * * *"
# or
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-modify.tfvars
```
- See [ops-examples/backup-modify.tfvars](mysql/ops-examples/backup-modify.tfvars)

#### 🔒 Termination Policies
Control cluster deletion behavior:
```bash
./run.sh -t 8 -tp "DoNotTerminate"
# or
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/termination-protect.tfvars
```
- See [ops-examples/termination-protect.tfvars](mysql/ops-examples/termination-protect.tfvars)

## 🎯 Learning Paths

### Path 1: Getting Started (15 minutes)
1. Choose your database engine
2. Read the engine-specific README
3. Run `./run.sh --help` to see options
4. Deploy your first cluster: `./run.sh -t 1`

### Path 2: Operations Mastery (1 hour)
1. Study run.sh script usage ([RUN_SCRIPT_GUIDE.md](mysql/RUN_SCRIPT_GUIDE.md))
2. Practice operations using CLI parameters
3. Learn tfvars overlay pattern
4. Master backup strategies

### Path 3: Production Ready (2 hours)
1. Review ops-examples/*.tfvars files
2. Understand parameterized configuration
3. Implement multi-zone deployments
4. Configure advanced backup with PITR
5. Create custom tfvars for complex scenarios

## 📖 Key Concepts

### Terraform Lifecycle → KubeBlocks OpsRequest

The provider translates Terraform operations into KubeBlocks actions:

| Terraform Action | KubeBlocks OpsRequest | Description |
|-----------------|----------------------|-------------|
| Create cluster | ClusterCreate | Provision new cluster |
| Change class_code | VerticalScale | Scale CPU/Memory |
| Change storage | VolumeExpand | Expand storage |
| Change replicas | HorizontalScale | Scale replicas/shards |
| Change params | Reconfigure | Update configuration |
| Modify backup | UpdateBackup | Update backup policy |
| Destroy cluster | ClusterDelete | Remove cluster |

### Common Operations

#### Vertical Scaling (VScale)
```hcl
# Change instance size
class_code = "mysql.replication.mysql.2c4g.general"  # 2 CPU, 4GB

# Increase storage
volumes = [
  {
    name    = "data"
    storage = 100  # GB - increased from 20
  }
]
```

#### Horizontal Scaling (HScale)
```hcl
# Add more replicas
components = [
  {
    component = "mysql"
    replicas  = 3  # increased from 2
  }
]
```

#### Parameter Changes
```hcl
# Apply new parameter template
param_tpls = [
  {
    component           = "mysql"
    param_tpl_name      = "mysql-8.0-high-performance-template"
    param_tpl_partition = "performance"
  }
]
```

## 🔧 Prerequisites

Before running examples, ensure you have:

1. **Terraform** installed (>= 1.0)
2. **KBCloud API credentials**:
   - `api_key` and `api_secret`
   - `admin_api_key` and `admin_api_secret`
3. **Network access** to your KBCloud API endpoint
4. **Proper RBAC permissions** in your organization

## 🚦 Running Examples

### Method 1: Using run.sh Script (Recommended)

```bash
cd example/mysql

# View help
./run.sh --help

# Create cluster with custom parameters
./run.sh -t 1 -cn "my-cluster" -r 3 -s 50

# Perform operations
./run.sh -t 4 -cc "mysql.replication.mysql.2c4g.general"  # VScale
./run.sh -t 5 -r 5                                        # HScale

# Destroy cluster
./run.sh -t 2
```

### Method 2: Using terraform.tfvars

#### Step 1: Initialize
```bash
cd example/mysql
terraform init
```

#### Step 2: Configure Credentials and Parameters
Copy the template and edit your configuration:
```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

Edit `terraform.tfvars` to set your values:
```hcl
# API Configuration
api_key    = "your-actual-api-key"
api_secret = "your-actual-api-secret"
admin_api_key    = "your-admin-api-key"
admin_api_secret = "your-admin-api-secret"

# Cluster Configuration
cluster_name     = "my-mysql"
display_name     = "My MySQL Cluster"
org_name         = "default-org"
environment_name = "prod"
project          = "kubeblocks-cloud-ns"

# Engine Configuration
engine  = "mysql"
version = "8.0.44"
mode    = "replication"

# Component Configuration
replicas        = 2
storage_size_gb = 20
class_code      = "mysql.replication.mysql.1c2g.general"

# Backup Configuration
auto_backup     = true
backup_repo     = "my-backuprepo"
retention_period = "7d"
```

#### Step 3: Plan
```bash
terraform plan -var-file=terraform.tfvars
```

#### Step 4: Apply
```bash
terraform apply -var-file=terraform.tfvars
```

#### Step 5: Verify
Check cluster status via:
- KubeBlocks dashboard
- kubectl commands
- KBCloud API

## ⚠️ Important Notes

### Safety First
- Always use `termination_policy = "DoNotTerminate"` for production
- Test changes in dev environment first
- Review `terraform plan` output before applying
- Backup critical data before major changes

### Cost Considerations
- More replicas = higher costs
- Larger instances = higher costs
- Longer backup retention = more storage costs
- Multi-zone deployments = higher network costs

### Performance Tips
- Use appropriate IOPS limits for your workload
- Separate volumes for data and logs (PostgreSQL, Kafka)
- Choose right instance size for your needs
- Monitor performance after scaling operations

## 🆘 Getting Help

### Documentation
- [Main README](README.md) - Overview of all examples
- Engine-specific READMEs - Detailed guides per database
- [Provider Documentation](../docs/) - Full API reference

### Troubleshooting
1. Check Terraform error messages
2. Review KubeBlocks OpsRequest status
3. Examine cluster events via kubectl
4. Verify API credentials and permissions

### Common Issues
- **Authentication errors**: Verify API keys and secrets
- **Resource not found**: Check org_name and environment_name
- **Scaling failures**: Ensure target class_code exists
- **Backup failures**: Verify backup_repo exists and is accessible

## 📝 Contributing

Found a bug or want to improve examples?
1. Check existing issues
2. Fork the repository
3. Make your changes
4. Submit a pull request

## 📄 License

These examples are provided under the same license as the terraform-provider-kbcloud project.

---

**Happy Terraforming!** 🎉

For questions or support, please refer to the official KubeBlocks documentation or contact your KBCloud administrator.
