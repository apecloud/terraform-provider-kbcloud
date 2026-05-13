# MSSQL Operations Examples

This directory contains example configurations for common MSSQL cluster operations.

## 📋 Available Operations

### 1. Vertical Scaling (VScale)
**File:** `vscale-up-compute.tfvars`

Scale compute resources (CPU/Memory) and/or storage:

```bash
# Scale up from 2c4g to 4c8g
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/vscale-up-compute.tfvars
```

### 2. Horizontal Scaling (HScale)
**File:** `hscale-out.tfvars`

Add or remove replicas:

```bash
# Scale out from 3 to 5 replicas
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/hscale-out.tfvars
```

### 3. Parameter Reconfiguration
**File:** `reconfigure-params.tfvars`

Modify database parameters:

```bash
# Change parameter template
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/reconfigure-params.tfvars
```

### 4. Backup Configuration
**File:** `backup-modify.tfvars`

Modify backup settings (PITR, schedule, retention):

```bash
# Enable PITR and configure backups
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/backup-modify.tfvars
```

### 5. Termination Policy
**File:** `termination-protect.tfvars`

Change cluster protection policy:

```bash
# Protect cluster from deletion
terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/termination-protect.tfvars
```

## 🚀 Quick Start

### Prerequisites

1. Initialize Terraform and create a cluster first:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your configuration
   terraform init
   terraform apply -var-file=terraform.tfvars
   ```

2. Verify cluster is running:
   ```bash
   kubectl get clusters -n kubeblocks-cloud-ns
   ```

### Performing Operations

All operations modify the **same cluster**. Simply apply the desired operation file:

```bash
# Example: Scale up compute
terraform plan \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/vscale-up-compute.tfvars

terraform apply \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/vscale-up-compute.tfvars
```

## 💡 Tips

### Combining Operations

You can combine multiple operations in a single apply:

```bash
# Scale up AND add replicas at the same time
cat > combined-ops.tfvars << EOF
class_code = "mssql.cluster.mssql.4c8g.performance"
replicas = 5
EOF

terraform apply \
  -var-file=terraform.tfvars \
  -var-file=combined-ops.tfvars
```

### Preview Before Applying

Always use `terraform plan` first to see what will change:

```bash
terraform plan \
  -var-file=terraform.tfvars \
  -var-file=ops-examples/vscale-up-compute.tfvars
```

### Monitor Operations

After applying, monitor the OpsRequest status:

```bash
kubectl get opsrequest -n kubeblocks-cloud-ns -w
kubectl describe opsrequest <ops-name> -n kubeblocks-cloud-ns
```

## ⚠️ Important Notes

1. **Single Cluster**: All operations modify the same cluster defined in `main.tf`
2. **No Downtime**: Most operations are online, but some may cause brief interruptions
3. **Backup First**: Always ensure you have recent backups before major changes
4. **Test in Dev**: Test operations in a development environment first

## 🔍 Troubleshooting

### Operation Stuck

Check OpsRequest status:
```bash
kubectl get opsrequest -n kubeblocks-cloud-ns
kubectl describe opsrequest <name> -n kubeblocks-cloud-ns
```

### Insufficient Resources

Verify resource quotas:
```bash
kubectl describe resourcequota -n kubeblocks-cloud-ns
```

### Check Logs

View operator logs:
```bash
kubectl logs -l app.kubernetes.io/name=kubeblocks -n kubeblocks-system --tail=100
```
