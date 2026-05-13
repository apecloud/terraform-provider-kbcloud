# ============================================================================
# Backup Operations Example Configuration for MSSQL
# ============================================================================
# This file demonstrates various backup configuration options
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-modify.tfvars
# ============================================================================

# Operation 1: Enable Auto Backup with full method
auto_backup        = true
auto_backup_method = "full"

# ============================================================================
# Operation 2: Change Backup Schedule
# Uncomment to change backup time
# ============================================================================
# cron_expression = "0 2 * * *"  # Daily at 2:00 AM

# ============================================================================
# Operation 3: Change Retention Policy
# Uncomment to keep more backups
# ============================================================================
# retention_period = "30d"  # Keep backups for 30 days
# retention_policy = "LastThree"  # Keep last 3 backups

# ============================================================================
# Operation 4: Enable Volume Snapshots
# Uncomment to enable snapshots
# ============================================================================
# snapshot_volumes = true
