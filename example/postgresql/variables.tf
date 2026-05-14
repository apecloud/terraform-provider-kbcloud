# ============================================================================
# KubeBlocks Cloud Provider Configuration
# ============================================================================

variable "api_url" {
  description = "KubeBlocks Cloud API endpoint URL"
  type        = string
  default     = "https://kb-cloud-apiserver-endpoint.com/api"
}

variable "api_key" {
  description = "API key for authentication"
  type        = string
  sensitive   = true
}

variable "api_secret" {
  description = "API secret for authentication"
  type        = string
  sensitive   = true
}

variable "admin_api_key" {
  description = "Admin API key for advanced operations"
  type        = string
  sensitive   = true
}

variable "admin_api_secret" {
  description = "Admin API secret for advanced operations"
  type        = string
  sensitive   = true
}

variable "https_skip_verify" {
  description = "Skip HTTPS certificate verification"
  type        = bool
  default     = false
}

# ============================================================================
# Cluster Basic Configuration
# ============================================================================

variable "cluster_name" {
  description = "Cluster name (must be unique)"
  type        = string
  default     = "my-pg"
}

variable "display_name" {
  description = "Display name for the cluster"
  type        = string
  default     = "My PostgreSQL Cluster"
}

variable "org_name" {
  description = "Organization name"
  type        = string
  default     = "default-org"
}

variable "environment_name" {
  description = "Environment name (dev/staging/prod)"
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Kubernetes namespace/project"
  type        = string
  default     = "kubeblocks-cloud-ns"
}

# ============================================================================
# Engine Configuration
# ============================================================================

variable "engine" {
  description = "Database engine type"
  type        = string
  default     = "postgresql"
}

variable "engine_version" {
  description = "Engine version"
  type        = string
  default     = "18.1.0"
}

variable "mode" {
  description = "Deployment mode"
  type        = string
  default     = "replication"
}

variable "cluster_type" {
  description = "Cluster type"
  type        = string
  default     = "Normal"
}

# ============================================================================
# Network and Availability
# ============================================================================

variable "single_zone" {
  description = "Deploy in single zone or multi-zone"
  type        = bool
  default     = true
}

variable "termination_policy" {
  description = "Termination policy (Delete/DoNotTerminate)"
  type        = string
  default     = "Delete"
  
  validation {
    condition     = contains(["Delete", "DoNotTerminate"], var.termination_policy)
    error_message = "Termination policy must be Delete or DoNotTerminate."
  }
}

# ============================================================================
# Maintenance Window
# ============================================================================

variable "maintenance_start_hour" {
  description = "Maintenance window start hour (0-23)"
  type        = number
  default     = 18
}

variable "maintenance_end_hour" {
  description = "Maintenance window end hour (0-23)"
  type        = number
  default     = 22
}

variable "maintenance_weekdays" {
  description = "Maintenance window weekdays (1-7, comma-separated)"
  type        = string
  default     = "1,2,3,4,5,6,7"
}

# ============================================================================
# Component Configuration
# ============================================================================

variable "component_name" {
  description = "Main component name"
  type        = string
  default     = "postgresql"
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 2
}

variable "storage_size_gb" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "storage_class" {
  description = "Storage class name"
  type        = string
  default     = "apelocal-rawdisk-xfs"
}

variable "class_code" {
  description = "Instance class code (CPU/Memory specification)"
  type        = string
  default     = "postgresql.replication.postgresql.1c2g.general"
}

# ============================================================================
# I/O Configuration (PostgreSQL specific)
# ============================================================================

variable "read_iops" {
  description = "Read IOPS limit"
  type        = number
  default     = 2000
}

variable "write_iops" {
  description = "Write IOPS limit"
  type        = number
  default     = 2000
}

# ============================================================================
# Parameter Template Configuration
# ============================================================================

variable "param_tpl_name" {
  description = "Parameter template name"
  type        = string
  default     = "postgresql-18.0-default-parameter-template"
}

variable "param_tpl_partition" {
  description = "Parameter template partition"
  type        = string
  default     = "default"
}

# ============================================================================
# Custom Parameters
# ============================================================================

variable "custom_params" {
  description = "Custom initialization parameters"
  type = map(string)
  default = {
    "timezone"     = "Asia/Shanghai"
    "log_timezone" = "Asia/Shanghai"
  }
}

variable "spec_name" {
  description = "Configuration spec name"
  type        = string
  default     = "postgresql-configuration"
}

# ============================================================================
# Custom Parameters
# ============================================================================

variable "custom_params" {
  description = "Custom initialization parameters"
  type = map(string)
  default = {}
}

variable "spec_name" {
  description = "Configuration spec name"
  type        = string
  default     = "postgresql-config"
}

variable "config_file_name" {
  description = "Configuration file name for reconfigure operation (e.g., postgresql.conf)"
  type        = string
  default     = ""
}

variable "reconfigure_component" {
  description = "Component name for reconfigure operation (if empty, uses the first component from components list)"
  type        = string
  default     = ""
}

# ============================================================================
# Backup Configuration
# ============================================================================

variable "backup_repo" {
  description = "Backup repository name"
  type        = string
  default     = "my-backuprepo"
}

variable "retention_period" {
  description = "Backup retention period"
  type        = string
  default     = "7d"
}

variable "retention_policy" {
  description = "Backup retention policy"
  type        = string
  default     = "LastOne"
}

variable "snapshot_volumes" {
  description = "Enable volume snapshots"
  type        = bool
  default     = false
}

variable "auto_backup" {
  description = "Enable automatic backup"
  type        = bool
  default     = true
}

variable "auto_backup_method" {
  description = "Auto backup method"
  type        = string
  default     = "wal-g-archive"
}

variable "cron_expression" {
  description = "Backup schedule (cron expression)"
  type        = string
  default     = "0 18 * * *"
}

variable "pitr_enabled" {
  description = "Enable Point-in-Time Recovery"
  type        = bool
  default     = true
}

variable "continuous_backup_method" {
  description = "Continuous backup method"
  type        = string
  default     = "wal-g-archive"
}

variable "incremental_backup_enabled" {
  description = "Enable incremental backup"
  type        = bool
  default     = false
}

variable "incremental_cron_expression" {
  description = "Incremental backup schedule (cron expression)"
  type        = string
  default     = "0 18 * * *"
}
