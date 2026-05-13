# MySQL Operations Examples

This directory contains Terraform variable files (`.tfvars`) that demonstrate different operations for MySQL clusters.

## 📋 Prerequisites

1. Copy the example configuration file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and fill in your sensitive information:
   ```hcl
   api_key    = "your_actual_api_key"
   api_secret = "your_actual_api_secret"
   admin_api_key    = "your_admin_api_key"
   admin_api_secret = "your_admin_api_secret"
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

## 🚀 Quick Start

### Create Initial Cluster

```bash
terraform apply -var-file=terraform.tfvars
```

This creates a MySQL cluster with default settings (2 replicas, 1c2g instance, 20GB storage).

---

## 🔧 Operations Guide

All operations use the **layered tfvars** approach:
- Base configuration: `terraform.tfvars`
- Operation overrides: `ops-examples/*.tfvars`

### 1️⃣ Vertical Scaling (VScale)

Scale compute resources (CPU/Memory) or storage.

#### Scale UP Compute

```bash
# Preview changes
terraform plan -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars

# Apply changes
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars
```

**What happens:** Instance class changes from `1c2g` (1 CPU, 2GB RAM) to `2c4g` (2 CPU, 4GB RAM).

#### Scale UP Storage

Create a custom tfvars file:
```bash
cat > ops-examples/vscale-up-storage.tfvars << EOF
storage_size_gb = 50
EOF

terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-storage.tfvars
```

**Important Notes:**
- ✅ You can **increase** storage at any time
- ❌ You **cannot decrease** storage once increased
- ⚠️ Scaling may cause brief downtime

---

### 2️⃣ Horizontal Scaling (HScale)

Add or remove replicas (nodes).

#### Scale OUT (Add Replicas)

```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/hscale-out.tfvars
```

**What happens:** Replicas increase from 2 to 3.

#### Scale IN (Remove Replicas)

Edit the hscale tfvars file:
```bash
sed -i 's/replicas = 3/replicas = 1/' ops-examples/hscale-out.tfvars
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/hscale-out.tfvars
```

**Important Notes:**
- Minimum replicas depends on mode (standalone: 1, replication: 1+)
- Primary node cannot be removed directly

---

### 3️⃣ Parameter Reconfiguration

Modify database parameters without recreating the cluster.

#### Modify Custom Parameters

```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-params.tfvars
```

**What changes:**
- Timezone: `+08:00` → `+09:00`
- Added: `max_connections = 500`
- Added: `innodb_buffer_pool_size = 1G`

#### Change Parameter Template

Create a custom tfvars:
```bash
cat > ops-examples/reconfigure-template.tfvars << EOF
param_tpl_name = "mysql-8.0-high-performance-template"
EOF

terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-template.tfvars
```

---

### 4️⃣ Backup Operations

Configure automatic backups, PITR, and retention policies.

#### Enable Automatic Backup

```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-enable-auto.tfvars
```

**What happens:**
- Enables daily backups at 2:00 AM
- Uses `xtrabackup` method
- Retains last backup only

#### Enable Point-in-Time Recovery (PITR)

Edit the backup tfvars:
```bash
cat > ops-examples/backup-enable-pitr.tfvars << EOF
auto_backup_enabled       = true
auto_backup_method        = "xtrabackup"
continuous_backup_enabled = true
continuous_backup_method  = "archive-binlog"
EOF

terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-enable-pitr.tfvars
```

#### Change Retention Policy

```bash
cat > ops-examples/backup-retention.tfvars << EOF
retention_policy = "7d"  # Keep backups for 7 days
EOF

terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-retention.tfvars
```

---

### 5️⃣ Termination Policy

Protect clusters from accidental deletion.

#### Enable Protection

```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/termination-protect.tfvars
```

**What happens:** Changes policy from `Delete` to `DoNotTerminate`.

**To delete the cluster later:**
```bash
# First, allow termination
terraform apply -var-file=terraform.tfvars -var='termination_policy=Delete'

# Then destroy
terraform destroy -var-file=terraform.tfvars
```

---

## 🎯 Common Workflows

### Workflow 1: Production Deployment

```bash
# 1. Create production cluster
terraform apply -var-file=terraform.tfvars

# 2. Scale up for production workload
terraform apply -var-file=terraform.tfvars \
  -var='class_code=mysql.replication.mysql.4c8g.general' \
  -var='storage_size_gb=100' \
  -var='replicas=3'

# 3. Enable backups
terraform apply -var-file=terraform.tfvars \
  -var='auto_backup_enabled=true' \
  -var='auto_backup_method=xtrabackup' \
  -var='backup_schedule=0 2 * * *' \
  -var='retention_policy=7d'

# 4. Protect from deletion
terraform apply -var-file=terraform.tfvars -var='termination_policy=DoNotTerminate'
```

### Workflow 2: Development Environment

```bash
# 1. Create small dev cluster
terraform apply -var-file=terraform.tfvars \
  -var='cluster_name=my-mysql-dev' \
  -var='environment_name=dev' \
  -var='class_code=mysql.replication.mysql.1c2g.general' \
  -var='replicas=1'

# 2. Allow easy cleanup
terraform apply -var-file=terraform.tfvars -var='termination_policy=Delete'

# ... do your work ...

# 3. Clean up
terraform destroy -var-file=terraform.tfvars
```

---

## 📝 Best Practices

1. **Use separate tfvars files** for different environments:
   - `terraform.tfvars.dev`
   - `terraform.tfvars.staging`
   - `terraform.tfvars.prod`

2. **Never commit sensitive data**:
   ```bash
   echo "terraform.tfvars" >> .gitignore
   ```

3. **Preview before applying**:
   ```bash
   terraform plan -var-file=terraform.tfvars -var-file=ops-examples/xxx.tfvars
   ```

4. **Test operations in dev first** before applying to production

5. **Monitor operations** via KubeBlocks dashboard or kubectl:
   ```bash
   kubectl get opsrequest -n kubeblocks-cloud-ns
   ```

---

## ❓ Troubleshooting

### Issue: "class_code not found"

**Solution:** Verify available classes in your environment:
```bash
kubectl get componentversions -A
```

### Issue: "Cannot decrease storage"

**Solution:** Storage can only be increased. To reduce, you must recreate the cluster.

### Issue: "Operation timeout"

**Solution:** Check OpsRequest status:
```bash
kubectl describe opsrequest <ops-name> -n kubeblocks-cloud-ns
```

---

## 🔗 Related Documentation

- [KubeBlocks Documentation](https://kubeblocks.io/docs)
- [Terraform Provider Docs](../../docs/)
- [MySQL Engine Options](../../../engineoption/mysql.json)
