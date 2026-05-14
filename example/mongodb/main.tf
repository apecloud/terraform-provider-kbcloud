terraform {
  required_providers {
    kbcloud = {
      source  = "registry.terraform.io/apecloud/kbcloud"
      version = "2.2.0-beta.2"
    }
  }
}

provider "kbcloud" {
  api_url        = var.api_url

  api_key        = var.api_key
  api_secret     = var.api_secret

  admin_api_key  = var.admin_api_key
  admin_api_secret = var.admin_api_secret

  # if you need to skip verify, please set https_skip_verify = true
  https_skip_verify = var.https_skip_verify
}


resource "kbcloud_cluster" "my_mongodb" {
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

  maintaince_window = {
    start_hour = var.maintenance_start_hour
    end_hour   = var.maintenance_end_hour
    weekdays   = var.maintenance_weekdays
  }

  components = var.mode == "sharding" ? [
    # Shard component
    {
      component     = var.shard_component_name
      comp_num      = var.shard_comp_num
      replicas      = var.shard_replicas
      storage_class = var.storage_class
      class_code    = var.shard_class_code
      
      volumes = [
        {
          name    = "data"
          storage = var.shard_storage_size_gb
          
          io_limits = {
            read_iops  = var.shard_read_iops
            write_iops = var.shard_write_iops
          }
          io_reserves = {
            read_iops  = var.shard_read_iops
            write_iops = var.shard_write_iops
          }
        }
      ]
    },
    # Config server component
    {
      component     = var.config_server_component_name
      replicas      = var.config_server_replicas
      storage_class = var.storage_class
      class_code    = var.config_server_class_code
      
      volumes = [
        {
          name    = "data"
          storage = var.config_server_storage_size_gb
          
          io_limits = {
            read_iops  = var.config_server_read_iops
            write_iops = var.config_server_write_iops
          }
          io_reserves = {
            read_iops  = var.config_server_read_iops
            write_iops = var.config_server_write_iops
          }
        }
      ]
    },
    # Mongos component (no volumes)
    {
      component  = var.mongos_component_name
      replicas   = var.mongos_replicas
      class_code = var.mongos_class_code
    }
  ] : [
    # Replicaset or standalone mode (single component)
    {
      component     = var.component_name
      replicas      = var.replicas
      storage_class = var.storage_class
      class_code    = var.class_code
      
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
  ]

  param_tpls = var.mode == "sharding" ? [
    {
      component           = var.shard_component_name
      param_tpl_name      = var.shard_param_tpl_name
      param_tpl_partition = var.param_tpl_partition
    },
    {
      component           = var.config_server_component_name
      param_tpl_name      = var.config_server_param_tpl_name
      param_tpl_partition = var.param_tpl_partition
    },
    {
      component           = var.mongos_component_name
      param_tpl_name      = var.mongos_param_tpl_name
      param_tpl_partition = var.param_tpl_partition
    }
  ] : [
    {
      component           = var.component_name
      param_tpl_name      = var.param_tpl_name
      param_tpl_partition = var.param_tpl_partition
    }
  ]

  init_options = [
    {
      component        = var.reconfigure_component != "" ? var.reconfigure_component : var.component_name
      init_params      = var.custom_params
      spec_name        = var.spec_name
      config_file_name = var.config_file_name != "" ? var.config_file_name : null
    }
  ]

  backup = {
    auto_backup                 = var.auto_backup
    auto_backup_method          = var.auto_backup_method != "" ? var.auto_backup_method : null
    backup_repo                 = var.backup_repo
    retention_period            = var.retention_period != "" ? var.retention_period : null
    retention_policy            = var.retention_policy
    cron_expression             = var.cron_expression != "" ? var.cron_expression : null
    snapshot_volumes            = var.snapshot_volumes
    pitr_enabled                = var.pitr_enabled
    continuous_backup_method    = var.continuous_backup_method != "" ? var.continuous_backup_method : null
    incremental_backup_enabled  = var.incremental_backup_enabled
    incremental_cron_expression = var.incremental_cron_expression != "" ? var.incremental_cron_expression : null
  }
}
