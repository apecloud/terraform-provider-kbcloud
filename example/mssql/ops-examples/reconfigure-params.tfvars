# ============================================================================
# Reconfigure (Parameter Modification) Example Configuration for MSSQL
# ============================================================================
# This file demonstrates how to modify MSSQL parameters
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-params.tfvars
# ============================================================================

# Method 1: Change parameter template
param_tpl_name = "mssql-default-parameter-template"

# Method 2: Modify custom parameters (if supported)
# custom_params = {
#   "max degree of parallelism" = "4"
#   "max server memory" = "8192"
# }
