# MySQL Terraform Examples - Operations Guide

This directory contains various operational examples for MySQL clusters, demonstrating different lifecycle operations supported by the KBCloud Terraform Provider.

## Examples Overview

### 1. Basic Cluster Creation
**File**: `main.tf`
- Creates a basic MySQL replication cluster
- Demonstrates fundamental configuration

### 2. Vertical Scaling (VScale)
**File**: `vscale.tf`
- Shows how to scale compute resources (CPU/Memory)
- Demonstrates storage expansion
- Changing class_code from smaller to larger instance types

### 3. Horizontal Scaling (HScale)
**File**: `hscale.tf`
- Shows how to increase/decrease replicas
- Demonstrates scaling from 2 to 3 replicas (or vice versa)

### 4. Parameter Reconfiguration
**File**: `reconfigure.tf`
- Shows how to apply different parameter templates
- Demonstrates changing init_options
- Triggers Reconfigure OpsRequest

### 5. Backup Configuration Changes
**Directory**: `ops-examples/backup-modify.tfvars`
- Shows how to modify backup policies
- Enable/disable PITR
- Change retention periods
- Configure incremental backups

### 6. Volume Expansion
**Directory**: `ops-examples/volume-expand-operation.tfvars`
- Shows how to expand storage for existing volumes
- Specify which PVC to expand using `volume_claim_template_name`
- Storage can only be increased, not decreased

### 7. Termination Policies
**File**: `termination.tf`
- Demonstrates Delete policy (allows terraform destroy)
- Demonstrates DoNotTerminate policy (prevents accidental deletion)

## Usage Instructions

### Vertical Scaling Example
To perform vertical scaling:
1. Start with the base configuration in `main.tf`
2. Apply it: `terraform apply`
3. Modify the `class_code` or `storage` values
4. Run `terraform apply` again to trigger VScale OpsRequest

Example change:
```hcl
# Before
class_code = "mysql.replication.mysql.1c2g.general"
storage = 20

# After
class_code = "mysql.replication.mysql.2c4g.general"
storage = 50
```

### Horizontal Scaling Example
To perform horizontal scaling:
1. Start with base configuration
2. Modify the `replicas` count in components
3. Run `terraform apply` to trigger HScale OpsRequest

Example change:
```hcl
# Before
replicas = 2

# After
replicas = 3
```

### Parameter Reconfiguration
To reconfigure parameters:
1. Update `param_tpl_name` or `param_tpl_id` in param_tpls block
2. Or modify `init_params` in init_options
3. Run `terraform apply` to trigger Reconfigure OpsRequest

### Volume Expansion
To expand storage:
1. Modify the `storage_size_gb` value in terraform.tfvars
2. Optionally specify `volume_claim_template_name` (default: "data")
3. Run `terraform apply` to trigger VolumeExpand OpsRequest

Example change:
```hcl
# Before
storage_size_gb = 20
volume_claim_template_name = "data"

# After
storage_size_gb = 100
volume_claim_template_name = "data"
```

Or using ops-examples overlay:
```bash
terraform apply -var-file=terraform.tfvars -var-file=ops-examples/volume-expand-operation.tfvars
```

## Important Notes

- **Storage Expansion Only**: You can increase storage but cannot decrease it
- **Replica Scaling**: Ensure your license supports the number of replicas
- **Maintenance Window**: Changes may only apply during configured maintenance windows
- **Termination Policy**: Set to "DoNotTerminate" for production clusters to prevent accidental deletion
