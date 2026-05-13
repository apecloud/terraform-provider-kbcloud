# ============================================================================
# HScale (Horizontal Scaling) Example Configuration
# ============================================================================
# This file demonstrates how to scale replicas (add/remove nodes)
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/hscale-out.tfvars
# ============================================================================

# Scale OUT: 2 replicas -> 3 replicas
replicas = 3

# ============================================================================
# Alternative: Scale IN (reduce replicas)
# Uncomment the following line to scale in
# Note: For MySQL replication, minimum is usually 1 primary
# ============================================================================
# replicas = 1
