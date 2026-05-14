# ============================================================================
# VScale (Vertical Scaling) Example Configuration for MongoDB
# ============================================================================
# This file demonstrates how to scale compute and storage resources
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/vscale-up-compute.tfvars
# ============================================================================

# Scale UP Compute: 1 CPU/1GB -> 2 CPU/2GB
class_code = "mongodb.replicaset.mongodb.2c2g.general"

# Note: For storage expansion, use ops-examples/volume-expand-operation.tfvars
