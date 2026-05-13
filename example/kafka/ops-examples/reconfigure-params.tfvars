# ============================================================================
# Reconfigure (Parameter Modification) Example Configuration for Kafka
# ============================================================================
# This file demonstrates how to modify Kafka parameters
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/reconfigure-params.tfvars
# ============================================================================

# Method 1: Change parameter template
param_tpl_name = "kafka-default-parameter-template"

# Method 2: Modify custom parameters (if supported)
# custom_params = {
#   "log.retention.hours" = "168"
#   "num.partitions" = "6"
#   "default.replication.factor" = "3"
# }
