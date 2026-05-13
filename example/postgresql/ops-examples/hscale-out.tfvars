# ============================================================================
# HScale (Horizontal Scaling) Example Configuration for PostgreSQL
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
# Note: For PostgreSQL replication, minimum is usually 1 primary
# ============================================================================
# replicas = 1
