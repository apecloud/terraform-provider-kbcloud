# Volume Expansion Operation
# 
# This file demonstrates how to expand storage for a cluster.
# Usage: terraform apply -var-file=terraform.tfvars -var-file=ops-examples/volume-expand-operation.tfvars
# Or using run.sh: ./run.sh -t 9 -s 100 -vct "data"

# Storage size in GB (must be larger than current size)
storage_size_gb = 100

# Volume claim template name (e.g., data, log, wal)
# This specifies which PVC to expand
volume_claim_template_name = "data"
