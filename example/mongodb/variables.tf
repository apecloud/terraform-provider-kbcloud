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
  default     = "my-mongodb"
}

variable "display_name" {
  description = "Display name for the cluster"
  type        = string
  default     = "My MongoDB Cluster"
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
  default     = "mongodb"
  
  validation {
    condition     = var.engine == "mongodb"
    error_message = "Engine must be mongodb."
  }
}

variable "engine_version" {
  description = "Engine version"
  type        = string
  default     = "6.0.27"
}

variable "mode" {
  description = "Deployment mode (standalone/replicaset/sharding)"
  type        = string
  default     = "replicaset"
  
  validation {
    condition     = contains(["standalone", "replicaset", "sharding"], var.mode)
    error_message = "Mode must be one of: standalone, replicaset, sharding."
  }
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
# Component Configuration (Primary - for replicaset/standalone)
# ============================================================================

variable "component_name" {
  description = "Main component name"
  type        = string
  default     = "mongodb"
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 3
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
  default     = "mongodb.replicaset.mongodb.1c1g.general"
}

# ============================================================================
# Sharding Mode Configuration
# ============================================================================

variable "shard_component_name" {
  description = "Shard component name (for sharding mode)"
  type        = string
  default     = "mongo-shard"
}

variable "shard_comp_num" {
  description = "Number of shards (for sharding mode)"
  type        = number
  default     = 2
}

variable "shard_replicas" {
  description = "Replicas per shard (for sharding mode)"
  type        = number
  default     = 3
}

variable "shard_storage_size_gb" {
  description = "Shard storage size in GB"
  type        = number
  default     = 20
}

variable "shard_read_iops" {
  description = "Shard read IOPS limit"
  type        = number
  default     = 1000
}

variable "shard_write_iops" {
  description = "Shard write IOPS limit"
  type        = number
  default     = 1000
}

variable "shard_class_code" {
  description = "Shard instance class code"
  type        = string
  default     = "mongodb.sharding.mongo-shard.1c1g.general"
}

# Config Server Configuration
variable "config_server_component_name" {
  description = "Config server component name"
  type        = string
  default     = "mongo-config-server"
}

variable "config_server_replicas" {
  description = "Config server replicas"
  type        = number
  default     = 3
}

variable "config_server_storage_size_gb" {
  description = "Config server storage size in GB"
  type        = number
  default     = 20
}

variable "config_server_read_iops" {
  description = "Config server read IOPS limit"
  type        = number
  default     = 1000
}

variable "config_server_write_iops" {
  description = "Config server write IOPS limit"
  type        = number
  default     = 1000
}

variable "config_server_class_code" {
  description = "Config server instance class code"
  type        = string
  default     = "mongodb.sharding.mongo-config-server.1c1g.general"
}

# Mongos Configuration
variable "mongos_component_name" {
  description = "Mongos component name"
  type        = string
  default     = "mongo-mongos"
}

variable "mongos_replicas" {
  description = "Mongos replicas"
  type        = number
  default     = 2
}

variable "mongos_class_code" {
  description = "Mongos instance class code"
  type        = string
  default     = "mongodb.sharding.mongo-mongos.1c1g.general"
}

# ============================================================================
# I/O Configuration (for replicaset/standalone)
# ============================================================================

variable "read_iops" {
  description = "Read IOPS limit"
  type        = number
  default     = 1000
}

variable "write_iops" {
  description = "Write IOPS limit"
  type        = number
  default     = 1000
}

# ============================================================================
# Parameter Template Configuration
# ============================================================================

variable "param_tpl_name" {
  description = "Parameter template name (primary component)"
  type        = string
  default     = "mongodb-default-parameter-template"
}

variable "param_tpl_partition" {
  description = "Parameter template partition"
  type        = string
  default     = "default"
}

# Sharding mode parameter templates
variable "shard_param_tpl_name" {
  description = "Shard parameter template name"
  type        = string
  default     = "mongo-shard-default-parameter-template"
}

variable "config_server_param_tpl_name" {
  description = "Config server parameter template name"
  type        = string
  default     = "mongo-config-server-default-parameter-template"
}

variable "mongos_param_tpl_name" {
  description = "Mongos parameter template name"
  type        = string
  default     = "mongo-mongos-default-parameter-template"
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
  default     = "pbm-physical"
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
  default     = "pbm-pitr"
}

variable "incremental_backup_enabled" {
  description = "Enable incremental backup"
  type        = bool
  default     = false
}

variable "incremental_cron_expression" {
  description = "Incremental backup schedule (cron expression)"
  type        = string
  default     = ""
}
