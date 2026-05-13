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
  default     = "my-mysql"
}

variable "display_name" {
  description = "Display name for the cluster"
  type        = string
  default     = "My MySQL Cluster"
}

variable "org_name" {
  description = "Organization name"
  type        = string
  default     = "my-org"
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
  default     = "mysql"
  
  validation {
    condition     = contains(["mysql", "postgresql", "redis", "mongodb", "kafka", "mssql"], var.engine)
    error_message = "Engine must be one of: mysql, postgresql, redis, mongodb, kafka, mssql."
  }
}

variable "engine_version" {
  description = "Engine version"
  type        = string
  default     = "8.0.44"
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
  default     = 22
}

variable "maintenance_end_hour" {
  description = "Maintenance window end hour (0-23)"
  type        = number
  default     = 18
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
  default     = "mysql"
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
  default     = "my-storage-class"
}

variable "class_code" {
  description = "Instance class code (CPU/Memory specification)"
  type        = string
  default     = "mysql.replication.mysql.1c2g.general"
}

# ============================================================================
# Parameter Template Configuration
# ============================================================================

variable "param_tpl_name" {
  description = "Parameter template name"
  type        = string
  default     = "mysql-8.0-default-parameter-template"
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
    "default-time-zone"      = "+08:00"
    "lower_case_table_names" = "1"
  }
}

variable "spec_name" {
  description = "Configuration spec name"
  type        = string
  default     = "mysql-replication-config"
}

# ============================================================================
# Backup Configuration
# ============================================================================

variable "backup_repo" {
  description = "Backup repository name"
  type        = string
  default     = "my-backuprepo"
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

variable "auto_backup_enabled" {
  description = "Enable automatic backup"
  type        = bool
  default     = false
}

variable "auto_backup_method" {
  description = "Auto backup method"
  type        = string
  default     = ""
}

variable "backup_schedule" {
  description = "Backup schedule (cron expression)"
  type        = string
  default     = ""
}

variable "continuous_backup_enabled" {
  description = "Enable continuous backup (PITR)"
  type        = bool
  default     = false
}

variable "continuous_backup_method" {
  description = "Continuous backup method"
  type        = string
  default     = ""
}
