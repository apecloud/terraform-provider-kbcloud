# ============================================================================
# Reconfigure (Parameter Modification) Example Configuration for PostgreSQL
# ============================================================================
# This file demonstrates how to modify database parameters
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-params.tfvars
# ============================================================================

# Method 1: Change parameter template
param_tpl_name = "postgresql-18.0-high-performance-template"

# Method 2: Modify custom parameters (if supported)
# custom_params = {
#   "shared_buffers" = "2GB"
#   "work_mem" = "64MB"
#   "maintenance_work_mem" = "512MB"
# }
