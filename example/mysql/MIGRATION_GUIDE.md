# Migration Guide: From Individual Files to Parameterized Structure

## 📌 Overview

The MySQL example has been refactored to reduce code duplication and improve maintainability.

### Before (Old Structure)
```
mysql/
├── main.tf              # Full cluster definition with hardcoded values
├── vscale.tf            # Duplicate cluster + VScale operations
├── hscale.tf            # Duplicate cluster + HScale operations
├── reconfigure.tf       # Duplicate cluster + Reconfigure operations
├── backup-ops.tf        # Duplicate cluster + Backup operations
└── termination.tf       # Duplicate cluster + Termination operations
```

**Problems:**
- ❌ Massive code duplication (same cluster defined 6 times)
- ❌ Hard to maintain (changes must be applied to all files)
- ❌ Not flexible (cannot easily customize parameters)
- ❌ Confusing (which file represents the "real" cluster?)

### After (New Structure)
```
mysql/
├── main.tf              # Single cluster definition using variables
├── variables.tf         # Variable definitions
├── terraform.tfvars.example  # Example configuration template
└── ops-examples/        # Operation-specific variable overrides
    ├── README.md
    ├── vscale-up-compute.tfvars
    ├── hscale-out.tfvars
    ├── reconfigure-params.tfvars
    ├── backup-enable-auto.tfvars
    └── termination-protect.tfvars
```

**Benefits:**
- ✅ Single source of truth (one cluster definition)
- ✅ DRY principle (no code duplication)
- ✅ Flexible (customize via tfvars)
- ✅ Clear separation (base config vs operation overrides)
- ✅ Easy to maintain (change once, applies everywhere)

---

## 🔄 How to Migrate

### Step 1: Review New Structure

Read the new [ops-examples/README.md](ops-examples/README.md) for detailed usage instructions.

### Step 2: Choose Your Approach

#### Option A: Use New Structure (Recommended)

1. Copy the example configuration:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your actual values:
   ```hcl
   api_key    = "your_api_key"
   api_secret = "your_api_secret"
   admin_api_key    = "your_admin_api_key"
   admin_api_secret = "your_admin_api_secret"
   ```

3. Create initial cluster:
   ```bash
   terraform init
   terraform apply -var-file=terraform.tfvars
   ```

4. Perform operations by layering tfvars:
   ```bash
   # Scale up compute
   terraform apply -var-file=terraform.tfvars \
     -var-file=ops-examples/vscale-up-compute.tfvars
   
   # Enable backups
   terraform apply -var-file=terraform.tfvars \
     -var-file=ops-examples/backup-enable-auto.tfvars
   ```

#### Option B: Keep Old Files (Temporary Compatibility)

If you're not ready to migrate, the old files are still there:
- `vscale.tf`
- `hscale.tf`
- `reconfigure.tf`
- `backup-ops.tf`
- `termination.tf`

⚠️ **Warning:** These files will be removed in a future version.

---

## 📖 Comparison Examples

### Example 1: Vertical Scaling

#### Old Way (vscale.tf)
```bash
# Edit vscale.tf directly, change class_code
# Then run:
terraform apply -f vscale.tf
```

**Issues:**
- Must edit the file manually
- File contains full cluster definition (70+ lines)
- Easy to make mistakes

#### New Way (tfvars overlay)
```bash
# No file editing needed!
terraform apply -var-file=terraform.tfvars \
  -var-file=ops-examples/vscale-up-compute.tfvars
```

**Benefits:**
- Clean, simple command
- Base config stays unchanged
- Easy to preview: `terraform plan` first

---

### Example 2: Multiple Operations

#### Old Way
```bash
# Step 1: Apply vscale
terraform apply -f vscale.tf

# Step 2: Edit backup-ops.tf
# Step 3: Apply backup
terraform apply -f backup-ops.tf

# Step 4: Edit termination.tf
# Step 5: Apply termination
terraform apply -f termination.tf
```

**Issues:**
- Multiple files to manage
- Each file is a separate cluster resource
- Risk of conflicts

#### New Way
```bash
# Combine multiple operations in one command!
terraform apply -var-file=terraform.tfvars \
  -var='class_code=mysql.replication.mysql.2c4g.general' \
  -var='auto_backup_enabled=true' \
  -var='termination_policy=DoNotTerminate'
```

**Benefits:**
- Single command
- All changes applied atomically
- No file editing required

---

## 🎯 Common Scenarios

### Scenario 1: Testing Different Configurations

**Old Way:**
- Create multiple copies of vscale.tf
- Manually edit each copy
- Risk of confusion

**New Way:**
```bash
# Create test configurations easily
cat > test-small.tfvars << EOF
class_code = "mysql.replication.mysql.1c2g.general"
replicas = 1
storage_size_gb = 10
EOF

cat > test-large.tfvars << EOF
class_code = "mysql.replication.mysql.8c16g.general"
replicas = 5
storage_size_gb = 500
EOF

# Test small
terraform apply -var-file=terraform.tfvars -var-file=test-small.tfvars

# Test large
terraform apply -var-file=terraform.tfvars -var-file=test-large.tfvars
```

---

### Scenario 2: Environment-Specific Configs

**New Way:**
```bash
# dev.tfvars
environment_name = "dev"
class_code = "mysql.replication.mysql.1c2g.general"
replicas = 1

# prod.tfvars
environment_name = "prod"
class_code = "mysql.replication.mysql.4c8g.general"
replicas = 3
storage_size_gb = 100
```

Deploy to different environments:
```bash
terraform apply -var-file=dev.tfvars
terraform apply -var-file=prod.tfvars
```

---

## 🗑️ Cleanup Old Files

Once you've migrated to the new structure, you can remove old files:

```bash
# Remove old individual operation files
rm vscale.tf hscale.tf reconfigure.tf backup-ops.tf termination.tf

# Keep only the essential files
ls -la
# main.tf
# variables.tf
# terraform.tfvars (your config)
# terraform.tfvars.example (template)
# ops-examples/ (operation examples)
```

---

## 📊 Code Reduction Statistics

| Metric | Old Structure | New Structure | Improvement |
|--------|---------------|---------------|-------------|
| Total .tf files | 6 | 2 | -67% |
| Lines of code | ~900 | ~350 | -61% |
| Code duplication | 5x | 0x | -100% |
| Maintenance effort | High | Low | Significant |

---

## ❓ FAQ

### Q: Can I still use the old files?
A: Yes, temporarily. But they will be removed in future versions.

### Q: Do I need to recreate my cluster?
A: No! The new structure manages the same cluster. Just switch to using tfvars.

### Q: What if I need a custom operation not in ops-examples?
A: Create your own `.tfvars` file or use inline variables:
```bash
terraform apply -var-file=terraform.tfvars \
  -var='custom_param=value'
```

### Q: Is this approach Terraform best practice?
A: Yes! This follows Terraform's recommended pattern of separating configuration (tfvars) from infrastructure code (.tf).

---

## 🔗 Additional Resources

- [Terraform Variables Documentation](https://developer.hashicorp.com/terraform/language/values/variables)
- [Terraform Input Variables Best Practices](https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables)
- [ops-examples/README.md](ops-examples/README.md) - Detailed operation guide
