# ============================================================================
# VScale (Vertical Scaling) Example Configuration for PostgreSQL
# ============================================================================
# This file demonstrates how to scale compute and storage resources
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars
# ============================================================================

# Scale UP Compute: 1 CPU/2GB -> 2 CPU/4GB
class_code = "postgresql.replication.postgresql.2c4g.general"

# Storage remains the same (20 GB)
# storage_size_gb = 20

# ============================================================================
# Alternative: Scale UP Both Compute and Storage
# Uncomment the following lines to scale both
# ============================================================================
# class_code = "postgresql.replication.postgresql.4c8g.performance"
# storage_size_gb = 100
