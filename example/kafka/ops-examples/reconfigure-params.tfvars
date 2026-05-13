# ============================================================================
# Reconfigure (Parameter Modification) Example Configuration for Redis
# ============================================================================
# This file demonstrates how to modify database parameters
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-params.tfvars
# ============================================================================

# Method 1: Change parameter template
param_tpl_name = "redis-high-performance-template"

# Method 2: Modify custom parameters (if supported)
# custom_params = {
#   "maxmemory" = "4gb"
#   "maxmemory-policy" = "allkeys-lru"
#   "timeout" = "300"
# }
