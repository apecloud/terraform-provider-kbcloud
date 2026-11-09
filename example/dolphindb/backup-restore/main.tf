terraform {
  required_providers {
    kbcloud = {
      source = "apecloud/kbcloud"
    }
  }
}

provider "kbcloud" {
  api_url          = var.api_url
  admin_api_key    = var.admin_api_key
  admin_api_secret = var.admin_api_secret
}

resource "kbcloud_backup" "snapshot" {
  org_name         = var.org_name
  cluster_name     = var.source_cluster_name
  backup_method    = var.selected_objects == null ? "native" : "native-selective"
  backup_type      = var.selected_objects == null ? "Full" : "Selective"
  component        = var.component
  retention_period = "7d"

  selected_objects_json = var.selected_objects == null ? null : jsonencode(var.selected_objects)
}

resource "kbcloud_restore" "recovery" {
  count = var.restore_enabled ? 1 : 0

  org_name              = var.org_name
  cluster_name          = var.target_cluster_name
  backup_name           = kbcloud_backup.snapshot.name
  component             = var.component
  selected_objects_json = var.selected_objects == null ? null : jsonencode(var.selected_objects)
  parameters            = var.selected_objects == null ? null : { conflict_policy = var.conflict_policy }
}

output "backup_id" {
  value = kbcloud_backup.snapshot.id
}
output "backup_name" {
  value = kbcloud_backup.snapshot.name
}
