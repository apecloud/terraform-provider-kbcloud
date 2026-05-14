# ============================================================================
# VScale (Vertical Scaling) Example Configuration for MSSQL
# ============================================================================
# This file demonstrates how to scale compute and storage resources
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars
# ============================================================================

# Scale UP Compute: 2 CPU/4GB -> 4 CPU/8GB
class_code = "mssql.cluster.mssql.4c8g.general"

# Note: For storage expansion, use ops-examples/volume-expand-operation.tfvars
