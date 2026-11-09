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

locals {
  topology = {
    standalone = ["standalone"]
    integrated = ["controller", "datanode"]
    separated  = ["controller", "datanode", "computenode"]
  }
}

resource "kbcloud_cluster" "dolphindb" {
  org_name           = var.org_name
  environment_name   = var.environment_name
  project            = var.project
  name               = var.cluster_name
  engine             = "dolphindb"
  version            = var.engine_version
  mode               = var.mode
  termination_policy = "Delete"

  components = [for component in local.topology[var.mode] : {
    component     = component
    replicas      = lookup(var.replicas, component, 1)
    class_code    = lookup(var.class_codes, component, "dolphindb.${var.mode}.${component}.1c2g.general")
    storage_class = var.storage_class
    volumes = [
      { name = "data", storage = lookup(var.data_storage, component, 10) },
      { name = "log", storage = lookup(var.log_storage, component, 1) }
    ]
  }]

  init_options = [for component in local.topology[var.mode] : {
    component        = component
    spec_name        = "dolphindb-config"
    config_file_name = "dolphindb.cfg"
    init_params      = var.parameters[component]
  } if contains(keys(var.parameters), component)]
}

output "cluster_id" {
  value = kbcloud_cluster.dolphindb.id
}
