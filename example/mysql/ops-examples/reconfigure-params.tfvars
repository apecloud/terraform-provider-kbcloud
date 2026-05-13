# ============================================================================
# Reconfigure (Parameter Modification) Example Configuration
# ============================================================================
# This file demonstrates how to modify database parameters
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-params.tfvars
# ============================================================================

# Method 1: Modify custom parameters
custom_params = {
  "default-time-zone"      = "+09:00"  # Changed from +08:00
  "lower_case_table_names" = "1"
  "max_connections"        = "500"     # New parameter
  "innodb_buffer_pool_size" = "1G"     # New parameter for performance
}

# Method 2: Change parameter template
# Uncomment to use a different template
# param_tpl_name = "mysql-8.0-high-performance-template"
