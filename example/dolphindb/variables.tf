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
variable "environment_name" { type = string }
variable "project" {
  type    = string
  default = "kubeblocks-cloud-ns"
}
variable "cluster_name" { type = string }
variable "engine_version" {
  type    = string
  default = "2.0.19"
}
variable "mode" {
  type    = string
  default = "standalone"
  validation {
    condition     = contains(["standalone", "integrated", "separated"], var.mode)
    error_message = "Use standalone, integrated or separated."
  }
}
variable "storage_class" { type = string }
variable "replicas" {
  type    = map(number)
  default = {}
}
variable "class_codes" {
  description = "Per-component class codes available in the target environment."
  type        = map(string)
  default     = {}
}
variable "data_storage" {
  type    = map(number)
  default = {}
}
variable "log_storage" {
  type    = map(number)
  default = {}
}
variable "parameters" {
  type    = map(map(string))
  default = {}
}
