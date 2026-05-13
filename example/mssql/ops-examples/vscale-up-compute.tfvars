# ============================================================================
# VScale (Vertical Scaling) Example Configuration for MSSQL
# ============================================================================
# This file demonstrates how to scale compute and storage resources
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars
# ============================================================================

# Scale UP Compute: 2 CPU/4GB -> 4 CPU/8GB
class_code = "mssql.cluster.mssql.4c8g.performance"

# Storage remains the same (20 GB)
# storage_size_gb = 20

# ============================================================================
# Alternative: Scale UP Both Compute and Storage
# Uncomment the following lines to scale both
# ============================================================================
# class_code = "mssql.cluster.mssql.8c16g.performance"
# storage_size_gb = 100
