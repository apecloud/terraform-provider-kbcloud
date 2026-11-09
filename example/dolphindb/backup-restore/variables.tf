variable "api_url" { type = string }
variable "admin_api_key" {
  type      = string
  sensitive = true
}
variable "admin_api_secret" {
  type      = string
  sensitive = true
}
variable "org_name" { type = string }
variable "source_cluster_name" { type = string }
variable "target_cluster_name" {
  type        = string
  default     = null
  description = "Required when restore_enabled is true. Use an empty compatible cluster for full recovery."
}
variable "component" {
  type        = string
  default     = "standalone"
  description = "standalone for standalone mode, datanode for integrated/separated mode."
}
variable "selected_objects" {
  type        = any
  default     = null
  description = "Recursive API selection tree; null selects a native full backup. See selective.tfvars.example."
}
variable "restore_enabled" {
  type    = bool
  default = false
}
variable "conflict_policy" {
  type    = string
  default = "FAIL"
  validation {
    condition     = contains(["FAIL", "OVERWRITE"], var.conflict_policy)
    error_message = "Use FAIL or OVERWRITE."
  }
}
