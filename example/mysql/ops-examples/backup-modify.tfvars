# ============================================================================
# Backup Operations Example Configuration for MySQL
# ============================================================================
# This file demonstrates various backup configuration options including:
# - Automatic backup enablement
# - Backup policy updates (retention, schedule, methods)
# - Point-in-Time Recovery (PITR)
# - Incremental backup
#
# Usage:
#   terraform apply -var-file=terraform.tfvars -var-file=ops-examples/backup-modify.tfvars
# ============================================================================

# ============================================================================
# Operation 1: Enable Automatic Backup (Quick Start)
# ============================================================================
# Uncomment to enable basic automatic backup with default settings
# ============================================================================
auto_backup = true
auto_backup_method = "xtrabackup"
cron_expression = "0 2 * * *"  # Daily at 2:00 AM UTC

# ============================================================================
# Operation 2: Configure Backup Retention
# ============================================================================
# Uncomment to set retention period and policy
# ============================================================================
# retention_period = "7d"        # Keep backups for 7 days
# retention_policy = "LastOne"   # Keep only the last backup when cluster is deleted

# Alternative retention policies:
# retention_policy = "LastThree"  # Keep last 3 backups
# retention_policy = "All"        # Keep all backups

# ============================================================================
# Operation 3: Enable Point-in-Time Recovery (PITR)
# ============================================================================
# Uncomment to enable continuous backup for PITR
# ============================================================================
# pitr_enabled = true
# continuous_backup_method = "binlog"  # Use binary log for continuous backup

# ============================================================================
# Operation 4: Enable Volume Snapshots
# ============================================================================
# Uncomment to enable volume snapshots for faster backup/restore
# ============================================================================
# snapshot_volumes = true

# ============================================================================
# Operation 5: Enable Incremental Backup
# ============================================================================
# Uncomment to enable incremental backups between full backups
# ============================================================================
# incremental_backup_enabled = true
# incremental_cron_expression = "0 */6 * * *"  # Every 6 hours

# ============================================================================
# Operation 6: Specify Backup Repository
# ============================================================================
# Uncomment to use a specific backup repository
# ============================================================================
# backup_repo = "my-backup-repo"

# ============================================================================
# Operation 7: Disable Automatic Backup
# ============================================================================
# Uncomment to disable automatic backup
# ============================================================================
# auto_backup = false

# ============================================================================
# Common Use Cases
# ============================================================================

# Use Case 1: Production Environment - Full backup daily + PITR
# --------------------------------------------------------------------------
# auto_backup = true
# auto_backup_method = "xtrabackup"
# cron_expression = "0 2 * * *"
# retention_period = "30d"
# retention_policy = "LastThree"
# pitr_enabled = true
# continuous_backup_method = "binlog"

# Use Case 2: Development Environment - Weekly backup only
# --------------------------------------------------------------------------
# auto_backup = true
# auto_backup_method = "xtrabackup"
# cron_expression = "0 3 * * 0"  # Sunday at 3:00 AM
# retention_period = "7d"
# retention_policy = "LastOne"
# pitr_enabled = false

# Use Case 3: High-Frequency Backup with Incremental
# --------------------------------------------------------------------------
# auto_backup = true
# auto_backup_method = "xtrabackup"
# cron_expression = "0 0 * * *"  # Daily at midnight
# incremental_backup_enabled = true
# incremental_cron_expression = "0 */4 * * *"  # Every 4 hours
# retention_period = "14d"
# retention_policy = "LastThree"

# Use Case 4: Disable All Backups (Not Recommended for Production)
# --------------------------------------------------------------------------
# auto_backup = false
# pitr_enabled = false
# incremental_backup_enabled = false
