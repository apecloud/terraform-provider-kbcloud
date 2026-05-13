# ============================================================================
# Reconfigure (Parameter Modification) Example Configuration for MongoDB
# ============================================================================
# This file demonstrates how to modify MongoDB parameters
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-params.tfvars
# ============================================================================

# Method 1: Change parameter template
param_tpl_name = "mongodb-default-parameter-template"

# Method 2: Modify custom parameters (if supported)
# custom_params = {
#   "storage.wiredTiger.engineConfig.cacheSizeGB" = "2"
#   "net.maxIncomingConnections" = "65536"
# }
