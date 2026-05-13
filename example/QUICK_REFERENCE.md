# KBCloud Terraform Operations Quick Reference

Quick reference guide for common operations across all database engines.

## 🔄 Operation Types

### 1️⃣ Vertical Scaling (VScale)
**What**: Scale CPU, Memory, or Storage of existing instances  
**Triggers**: VerticalScale OpsRequest  
**Downtime**: Brief restart may occur

#### How to VScale

**Method 1: Using run.sh script (Recommended)**
```bash
./run.sh -t 4 -cc "mysql.replication.mysql.2c4g.general"
```

**Method 2: Using tfvars overlay**
```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars
```

**Method 3: Direct configuration in terraform.tfvars**
```hcl
# Scale Compute
class_code = "mysql.replication.mysql.2c4g.general"  # Change instance type

# Scale Storage
storage_size_gb = 100  # Increase from current size

# Add IOPS limits
read_iops  = 5000
write_iops = 5000
```

**Examples**: 
- [vscale-up-compute.tfvars](mysql/ops-examples/vscale-up-compute.tfvars)
- See engine-specific RUN_SCRIPT_GUIDE.md for details

---

### 2️⃣ Horizontal Scaling (HScale)
**What**: Add/remove replicas or shards  
**Triggers**: HorizontalScale OpsRequest  
**Downtime**: None (online operation)

#### How to HScale

**Method 1: Using run.sh script (Recommended)**
```bash
./run.sh -t 5 -r 5
```

**Method 2: Using tfvars overlay**
```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/hscale-out.tfvars
```

**Method 3: Direct configuration in terraform.tfvars**
```hcl
# Scale Replicas
replicas = 5  # Increase/decrease count

# Scale Shards (Redis Cluster, MongoDB Sharding)
mode = "cluster"  # or "sharding"
comp_num = 6  # Number of shards
```

**Examples**:
- [hscale-out.tfvars](mysql/ops-examples/hscale-out.tfvars)
- **Note**: MSSQL does not support HScale

---

### 3️⃣ Parameter Reconfiguration
**What**: Change database configuration parameters  
**Triggers**: Reconfigure OpsRequest  
**Downtime**: May require restart for some parameters

#### How to Reconfigure

**Method 1: Using run.sh script (Recommended)**
```bash
./run.sh -t 6 -cp '{"max_connections": "500"}'
```

**Method 2: Using tfvars overlay**
```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-params.tfvars
```

**Method 3: Direct configuration in terraform.tfvars**
```hcl
# Method 1: Change Parameter Template
param_tpl_name = "mysql-8.0-high-performance-template"
param_tpl_partition = "performance"

# Method 2: Custom Init Parameters (if supported)
init_params = {
  "max_connections" = "2000"
  "innodb_buffer_pool_size" = "4G"
}
```

**Examples**:
- [reconfigure-params.tfvars](mysql/ops-examples/reconfigure-params.tfvars)

---

### 4️⃣ Backup Configuration
**What**: Modify backup policies and schedules  
**Triggers**: UpdateBackup OpsRequest  
**Downtime**: None

#### How to Configure Backup

**Method 1: Using run.sh script (Recommended)**
```bash
./run.sh -t 7 -ab true -bm "xtrabackup" -bs "0 2 * * *"
```

**Method 2: Using tfvars overlay**
```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-modify.tfvars
```

**Method 3: Direct configuration in terraform.tfvars**
```hcl
# Basic backup
backup_repo      = "my-backuprepo"
retention_policy = "LastOne"

# Enable auto backup
auto_backup        = true
auto_backup_method = "physical"
backup_schedule    = "0 2 * * *"
retention_period   = "7d"

# Enable PITR
pitr_enabled             = true
continuous_backup_method = "binlog"  # MySQL

# Incremental backups
incremental_backup_enabled  = true
incremental_cron_expression = "0 */6 * * *"
```

**Examples**:
- [backup-modify.tfvars](mysql/ops-examples/backup-modify.tfvars)

---

### 5️⃣ Termination Policy
**What**: Control whether cluster can be deleted  
**Triggers**: None (policy change only)  
**Downtime**: None

#### How to Set Termination Policy

**Method 1: Using run.sh script (Recommended)**
```bash
./run.sh -t 8 -tp "DoNotTerminate"
```

**Method 2: Using tfvars overlay**
```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/termination-protect.tfvars
```

**Method 3: Direct configuration in terraform.tfvars**
```hcl
# Allow deletion (dev/test)
termination_policy = "Delete"

# Prevent deletion (production)
termination_policy = "DoNotTerminate"
```

**Examples**:
- [termination-protect.tfvars](mysql/ops-examples/termination-protect.tfvars)

---

## 📊 Engine-Specific Features

### MySQL
| Feature | Configuration |
|---------|--------------|
| Modes | `standalone`, `replication` |
| Backup Methods | `physical`, `logical` |
| Continuous Backup | `binlog` |
| Min Replicas | 1 (standalone), 2 (replication) |

### PostgreSQL
| Feature | Configuration |
|---------|--------------|
| Modes | `standalone`, `replication` |
| Backup Methods | `wal-g` |
| Continuous Backup | `wal-g-archive` |
| Special Volumes | `data`, `wal` |
| Min Replicas | 1 (standalone), 2 (replication) |

### Redis
| Feature | Configuration |
|---------|--------------|
| Modes | `standalone`, `replication`, `sentinel`, `cluster` |
| Backup Methods | `rdb`, `aof` |
| Sharding | `comp_num` in cluster mode |
| Network Modes | `HeadlessService`, `HostNetwork` |

### MongoDB
| Feature | Configuration |
|---------|--------------|
| Modes | `standalone`, `replicaset`, `sharding` |
| Backup Methods | `pbm-physical` |
| Continuous Backup | `pbm-pitr` |
| Components | `mongo-shard`, `mongo-config-server`, `mongo-mongos` |

### Kafka
| Feature | Configuration |
|---------|--------------|
| Modes | `combined`, `separated`, `withZookeeper-*` |
| Backup Methods | `topics` |
| Components | `kafka-combine`, `kafka-broker`, `kafka-controller` |
| Security | SASL via `extra.sasl.enable` |

### MSSQL
| Feature | Configuration |
|---------|--------------|
| Modes | `cluster` (Always On AG) |
| Backup Methods | `full`, `transaction-log` |
| Editions | `Enterprise`, `Standard` |
| Collation | Via `extra.collation` |

---

## 🎯 Common Scenarios

### Scenario 1: Dev → Prod Migration

**Step 1: Start with dev configuration (terraform.tfvars)**
```hcl
termination_policy = "Delete"
class_code = "mysql.replication.mysql.1c2g.general"
replicas = 2
storage_size_gb = 20
```

**Step 2: Test thoroughly**
```bash
./run.sh -t 1  # Create dev cluster
# Run your tests...
```

**Step 3: Upgrade to production (update terraform.tfvars)**
```hcl
termination_policy = "DoNotTerminate"
class_code = "mysql.replication.mysql.4c8g.performance"
replicas = 3
storage_size_gb = 100
single_zone = false  # Multi-zone for HA
```

**Step 4: Apply production changes**
```bash
./run.sh -t 4 -cc "mysql.replication.mysql.4c8g.performance"  # VScale
./run.sh -t 5 -r 3                                            # HScale
./run.sh -t 8 -tp "DoNotTerminate"                            # Protect from deletion
```

---

### Scenario 2: Emergency Scale-Up

**Traffic spike - need more capacity NOW**

Using run.sh (fastest):
```bash
# Scale up compute and replicas immediately
./run.sh -t 4 -cc "mysql.replication.mysql.8c16g.performance"
./run.sh -t 5 -r 5
```

Or using tfvars overlay:
```bash
# Create emergency-scale.tfvars
cat > emergency-scale.tfvars << EOF
class_code = "mysql.replication.mysql.8c16g.performance"
replicas = 5
storage_size_gb = 200
EOF

# Apply immediately
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=emergency-scale.tfvars
```

---

### Scenario 3: Cost Optimization

**Reduce costs during off-peak hours**

Using run.sh:
```bash
# Downgrade compute and reduce replicas
./run.sh -t 4 -cc "mysql.replication.mysql.2c4g.general"
./run.sh -t 5 -r 2
```

Or using tfvars:
```hcl
# In terraform.tfvars or cost-optimization.tfvars
class_code = "mysql.replication.mysql.2c4g.general"
replicas = 2
storage_size_gb = 50  # If you can reduce storage
```

Apply the changes:
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=cost-optimization.tfvars
```

---

### Scenario 4: Enable Backup and PITR

**Add backup protection to existing cluster**

Using run.sh:
```bash
./run.sh -t 7 \
  -ab true \
  -bm "xtrabackup" \
  -bs "0 2 * * *" \
  -rp "7d" \
  -pitr true \
  -cbm "binlog"
```

Or using tfvars:
```hcl
# In backup-enable.tfvars
auto_backup_enabled      = true
auto_backup_method       = "xtrabackup"
backup_schedule          = "0 2 * * *"
retention_period         = "7d"
pitr_enabled             = true
continuous_backup_method = "binlog"
```

Apply:
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=backup-enable.tfvars
```

---

## ⚡ Quick Commands

### Initialize
```bash
terraform init
```

### Preview Changes
```bash
terraform plan -var-file=terraform.tfvars
```

### Apply Changes
```bash
terraform apply -var-file=terraform.tfvars
```

### Apply with Operation Overlay
```bash
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/vscale-up-compute.tfvars
```

### Using run.sh Script (All-in-One)
```bash
# Create cluster
./run.sh -t 1 -cn "my-cluster" -r 3 -s 50

# Perform operations
./run.sh -t 4 -cc "mysql.replication.mysql.2c4g.general"  # VScale
./run.sh -t 5 -r 5                                        # HScale
./run.sh -t 6 -cp '{"max_connections": "500"}'            # Reconfigure
./run.sh -t 7 -ab true -bm "xtrabackup"                   # Backup
./run.sh -t 8 -tp "DoNotTerminate"                        # Termination

# Destroy cluster
./run.sh -t 2
```

### Destroy Cluster
```bash
terraform destroy -var-file=terraform.tfvars
```

### Target Specific Resource
```bash
terraform apply -target=kbcloud_cluster.my_mysql -var-file=terraform.tfvars
```

### View State
```bash
terraform state list
terraform show
```

---

## 🔍 Monitoring Operations

### Check OpsRequest Status
```bash
kubectl get opsrequest -n <namespace>
kubectl describe opsrequest <opsrequest-name> -n <namespace>
```

### Check Cluster Status
```bash
kubectl get cluster -n <namespace>
kubectl describe cluster <cluster-name> -n <namespace>
```

### View Events
```bash
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

---

## 💡 Best Practices

### ✅ DO
- Use `DoNotTerminate` for production
- Test changes in dev first
- Review `terraform plan` before applying
- Monitor operations after applying
- Use appropriate IOPS limits
- Enable backups with PITR for critical data
- Distribute across availability zones

### ❌ DON'T
- Decrease storage (not supported)
- Make multiple major changes at once
- Skip planning phase
- Ignore operation status
- Use same config for dev and prod
- Disable backups for production
- Deploy single-zone for critical workloads

---

## 📞 Support

- **Documentation**: See engine-specific README files
- **API Reference**: Check KubeBlocks documentation
- **Issues**: Review terraform plan output for errors
- **Logs**: Check KubeBlocks operator logs

---

**Remember**: Always test in a non-production environment before applying changes to production clusters!
