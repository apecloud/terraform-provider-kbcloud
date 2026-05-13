# ============================================================================
# Backup Operations Example Configuration
# ============================================================================
# This file demonstrates various backup configuration options
# 
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-enable-auto.tfvars
# ============================================================================

# Operation 1: Enable Automatic Backup
auto_backup        = true
auto_backup_method = "xtrabackup"
cron_expression    = "0 2 * * *"  # Daily at 2:00 AM

# ============================================================================
# Operation 2: Enable Continuous Backup (PITR - Point-in-Time Recovery)
# Uncomment the following lines to enable PITR
# ============================================================================
# pitr_enabled = true
# continuous_backup_method  = "archive-binlog"

# ============================================================================
# Operation 3: Enable Volume Snapshots
# Uncomment to enable volume snapshots for faster backup/restore
# ============================================================================
# snapshot_volumes = true

# ============================================================================
# Operation 4: Change Retention Policy
# Uncomment to keep more backups
# ============================================================================
# retention_policy = "7d"  # Keep backups for 7 days
# Or: retention_policy = "LastThree"  # Keep last 3 backups
