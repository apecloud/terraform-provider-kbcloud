# ============================================================================
# Backup Operations Example Configuration for PostgreSQL
# ============================================================================
# This file demonstrates various backup configuration options
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-modify.tfvars
# ============================================================================

# Operation 1: Enable PITR (Point-in-Time Recovery)
pitr_enabled = true
continuous_backup_method = "wal-g-archive"

# ============================================================================
# Operation 2: Change Backup Schedule
# Uncomment to change backup time
# ============================================================================
# cron_expression = "0 2 * * *"  # Daily at 2:00 AM

# ============================================================================
# Operation 3: Enable Incremental Backup
# Uncomment to enable incremental backups
# ============================================================================
# incremental_backup_enabled = true
# incremental_cron_expression = "0 */6 * * *"  # Every 6 hours

# ============================================================================
# Operation 4: Change Retention Policy
# Uncomment to keep more backups
# ============================================================================
# retention_period = "30d"  # Keep backups for 30 days
# retention_policy = "LastThree"  # Keep last 3 backups
