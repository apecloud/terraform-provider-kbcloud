terraform {
  required_providers {
    kbcloud = {
      source  = "registry.terraform.io/apecloud/kbcloud"
      version = "2.2.0-beta.0"
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

resource "kbcloud_cluster" "my_redis" {
  name             = var.cluster_name
  display_name     = var.display_name
  org_name         = var.org_name
  environment_name = var.environment_name
  engine           = var.engine
  version          = var.engine_version
  mode             = var.mode
  cluster_type     = var.cluster_type
  project          = var.project

  single_zone        = var.single_zone
  termination_policy = var.termination_policy
  
  dynamic "network_mode" {
    for_each = var.network_mode != "" ? [var.network_mode] : []
    content {
      network_mode = network_mode.value
    }
  }
  
  dynamic "extra" {
    for_each = var.mode == "sentinel" ? [1] : []
    content {
      sentinel = var.extra_sentinel
    }
  }
  
  maintaince_window = {
    start_hour = var.maintenance_start_hour
    end_hour   = var.maintenance_end_hour
    weekdays   = var.maintenance_weekdays
  }

  components = concat(
    [
      {
        component     = var.component_name
        replicas      = var.replicas
        storage_class = var.storage_class
        class_code    = var.class_code
        
        # Add comp_num for cluster mode
        comp_num = var.mode == "cluster" ? var.comp_num : null
        
        volumes = [
          {
            name    = "data"
            storage = var.storage_size_gb
            
            io_limits = {
              read_iops  = var.read_iops
              write_iops = var.write_iops
            }
            io_reserves = {
              read_iops  = var.read_iops
              write_iops = var.write_iops
            }
          }
        ]
      }
    ],
    # Add sentinel component for sentinel mode
    var.mode == "sentinel" ? [
      {
        component     = var.sentinel_component_name
        replicas      = var.sentinel_replicas
        storage_class = var.storage_class
        class_code    = var.sentinel_class_code
        
        volumes = [
          {
            name    = "data"
            storage = var.sentinel_storage_size_gb
            
            io_limits = {
              read_iops  = var.sentinel_read_iops
              write_iops = var.sentinel_write_iops
            }
            io_reserves = {
              read_iops  = var.sentinel_read_iops
              write_iops = var.sentinel_write_iops
            }
          }
        ]
      }
    ] : []
  )

  param_tpls = [
    {
      component           = var.component_name
      param_tpl_name      = var.param_tpl_name
      param_tpl_partition = var.param_tpl_partition
    }
  ]

  backup = {
    auto_backup              = var.auto_backup_enabled
    auto_backup_method       = var.auto_backup_method
    backup_repo              = var.backup_repo
    retention_period         = var.retention_period
    retention_policy         = var.retention_policy
    cron_expression          = var.backup_schedule
    snapshot_volumes         = var.snapshot_volumes
    pitr_enabled             = var.pitr_enabled
    continuous_backup_method = var.continuous_backup_method
  }
}
