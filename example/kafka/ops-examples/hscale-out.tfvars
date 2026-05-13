# ============================================================================
# HScale (Horizontal Scaling) Example Configuration for Kafka
# ============================================================================
# This file demonstrates how to scale replicas (add/remove nodes)
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/hscale-out.tfvars
# ============================================================================

# Scale OUT: 3 replicas -> 5 replicas
replicas = 5

# ============================================================================
# Alternative: Scale IN (reduce replicas)
# Uncomment the following line to scale in
# Note: For Kafka, minimum is usually 3 replicas for production
# ============================================================================
# replicas = 3
