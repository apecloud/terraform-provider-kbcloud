# ============================================================================
# VScale (Vertical Scaling) Example Configuration for Redis
# ============================================================================
# This file demonstrates how to scale compute and storage resources
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars
# ============================================================================

# Scale UP Compute: 2 CPU/2GB -> 4 CPU/4GB
class_code = "redis.replication.redis.4c8g.general"

# Note: For storage expansion, use ops-examples/volume-expand-operation.tfvars
