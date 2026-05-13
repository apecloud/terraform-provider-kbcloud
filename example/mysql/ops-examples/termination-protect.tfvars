# ============================================================================
# Termination Policy Example Configuration
# ============================================================================
# This file demonstrates how to change termination policies
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/termination-protect.tfvars
# ============================================================================

# Change to DoNotTerminate to protect the cluster from accidental deletion
termination_policy = "DoNotTerminate"

# ============================================================================
# To allow deletion again, change back to:
# termination_policy = "Delete"
# ============================================================================
