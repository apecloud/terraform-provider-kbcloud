# ============================================================================
# VScale (Vertical Scaling) Example Configuration for Redis
# ============================================================================
# This file demonstrates how to scale compute and storage resources
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars
# ============================================================================

# Scale UP Compute: 2 CPU/2GB -> 4 CPU/4GB
class_code = "redis.replication.redis.4c4g.performance"

# Storage remains the same (30 GB)
# storage_size_gb = 30

# ============================================================================
# Alternative: Scale UP Both Compute and Storage
# Uncomment the following lines to scale both
# ============================================================================
# class_code = "redis.replication.redis.8c8g.performance"
# storage_size_gb = 100
