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
  default     = "my-kafka"
}

variable "display_name" {
  description = "Display name for the cluster"
  type        = string
  default     = "My Kafka Cluster"
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
  default     = "kafka"
  
  validation {
    condition     = var.engine == "kafka"
    error_message = "Engine must be kafka."
  }
}

variable "engine_version" {
  description = "Engine version"
  type        = string
  default     = "3.9.0"
}

variable "mode" {
  description = "Deployment mode (combined/separated/withZookeeper)"
  type        = string
  default     = "combined"
  
  validation {
    condition     = contains(["combined", "separated"], var.mode) || can(regex("^withZookeeper-", var.mode))
    error_message = "Mode must be combined, separated, or withZookeeper-*."
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

variable "network_mode" {
  description = "Network mode"
  type        = string
  default     = "HeadlessService"
}

# ============================================================================
# SASL Configuration
# ============================================================================

variable "sasl_enabled" {
  description = "Enable SASL authentication"
  type        = bool
  default     = true
}

# ============================================================================
# Service References (for withZookeeper mode)
# ============================================================================

variable "zookeeper_cluster_ref" {
  description = "Zookeeper cluster reference (for withZookeeper mode)"
  type        = string
  default     = ""
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
# Combined Mode Configuration
# ============================================================================

variable "combined_component_name" {
  description = "Combined component name"
  type        = string
  default     = "kafka-combine"
}

variable "combined_replicas" {
  description = "Combined mode replicas"
  type        = number
  default     = 1
}

variable "combined_data_storage_gb" {
  description = "Combined mode data storage in GB"
  type        = number
  default     = 20
}

variable "combined_metadata_storage_gb" {
  description = "Combined mode metadata storage in GB"
  type        = number
  default     = 5
}

variable "combined_read_iops" {
  description = "Combined mode read IOPS limit"
  type        = number
  default     = 1000
}

variable "combined_write_iops" {
  description = "Combined mode write IOPS limit"
  type        = number
  default     = 1000
}

variable "combined_class_code" {
  description = "Combined mode instance class code"
  type        = string
  default     = "kafka.combined.kafka-combine.1c1g.general"
}

# ============================================================================
# Separated Mode Configuration
# ============================================================================

variable "broker_component_name" {
  description = "Broker component name"
  type        = string
  default     = "kafka-broker"
}

variable "broker_replicas" {
  description = "Broker replicas"
  type        = number
  default     = 3
}

variable "broker_data_storage_gb" {
  description = "Broker data storage in GB"
  type        = number
  default     = 20
}

variable "broker_read_iops" {
  description = "Broker read IOPS limit"
  type        = number
  default     = 1000
}

variable "broker_write_iops" {
  description = "Broker write IOPS limit"
  type        = number
  default     = 1000
}

variable "broker_class_code" {
  description = "Broker instance class code"
  type        = string
  default     = "kafka.separated.kafka-broker.1c1g.general"
}

# Controller Configuration
variable "controller_component_name" {
  description = "Controller component name"
  type        = string
  default     = "kafka-controller"
}

variable "controller_replicas" {
  description = "Controller replicas"
  type        = number
  default     = 3
}

variable "controller_metadata_storage_gb" {
  description = "Controller metadata storage in GB"
  type        = number
  default     = 5
}

variable "controller_read_iops" {
  description = "Controller read IOPS limit"
  type        = number
  default     = 1000
}

variable "controller_write_iops" {
  description = "Controller write IOPS limit"
  type        = number
  default     = 1000
}

variable "controller_class_code" {
  description = "Controller instance class code"
  type        = string
  default     = "kafka.separated.kafka-controller.1c1g.general"
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

variable "auto_backup_enabled" {
  description = "Enable automatic backup"
  type        = bool
  default     = true
}

variable "auto_backup_method" {
  description = "Auto backup method"
  type        = string
  default     = "topics"
}

variable "backup_schedule" {
  description = "Backup schedule (cron expression)"
  type        = string
  default     = "0 18 * * *"
}
