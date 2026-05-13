terraform {
  required_providers {
    kbcloud = {
      source = "registry.terraform.io/apecloud/kbcloud"
    }
  }
}

provider "kbcloud" {
  api_url = var.api_url

  api_key    = var.api_key
  api_secret = var.api_secret

  admin_api_key    = var.admin_api_key
  admin_api_secret = var.admin_api_secret

  # if you need to skip verify, please set https_skip_verify = true
  https_skip_verify = var.https_skip_verify
}

resource "kbcloud_cluster" "my_mysql" {
  name             = var.cluster_name
  display_name     = var.display_name
  org_name         = var.org_name
  environment_name = var.environment_name
  engine           = var.engine
  version          = var.version
  mode             = var.mode
  cluster_type     = var.cluster_type
  project          = var.project
  single_zone      = var.single_zone
  termination_policy = var.termination_policy
  
  maintaince_window = {
    start_hour = var.maintenance_start_hour
    end_hour   = var.maintenance_end_hour
    weekdays   = var.maintenance_weekdays
  }
  
  param_tpls = [
    {
      component           = var.component_name
      param_tpl_name      = var.param_tpl_name
      param_tpl_partition = var.param_tpl_partition
    }
  ]

  init_options = [
    {
      component   = var.component_name
      init_params = var.custom_params
      spec_name   = var.spec_name
    }
  ]

  components = [
    {
      component     = var.component_name
      replicas      = var.replicas
      storage_class = var.storage_class
      class_code    = var.class_code
      
      volumes = [
        {
          name    = "data"
          storage = var.storage_size_gb
        }
      ]
    }
  ]

  backup = {
    backup_repo              = var.backup_repo
    retention_policy         = var.retention_policy
    snapshot_volumes         = var.snapshot_volumes
    auto_backup_enabled      = var.auto_backup_enabled
    auto_backup_method       = var.auto_backup_method != "" ? var.auto_backup_method : null
    backup_schedule          = var.backup_schedule != "" ? var.backup_schedule : null
    continuous_backup_enabled = var.continuous_backup_enabled
    continuous_backup_method = var.continuous_backup_method != "" ? var.continuous_backup_method : null
  }
}
