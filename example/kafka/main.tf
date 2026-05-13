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


resource "kbcloud_cluster" "my_kafka" {
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
  network_mode       = var.network_mode

  extra = {
    sasl = {
      enable = var.sasl_enabled
    }
  }
  
  dynamic "service_refs" {
    for_each = var.zookeeper_cluster_ref != "" ? [1] : []
    content {
      name    = "zookeeper"
      cluster = var.zookeeper_cluster_ref
    }
  }

  maintaince_window = {
    start_hour = var.maintenance_start_hour
    end_hour   = var.maintenance_end_hour
    weekdays   = var.maintenance_weekdays
  }

  components = var.mode == "combined" ? [
    # Combined mode: single component with data and metadata volumes
    {
      component     = var.combined_component_name
      replicas      = var.combined_replicas
      storage_class = "apelocal-rawdisk-xfs"
      class_code    = var.combined_class_code
      
      volumes = [
        {
          name    = "data"
          storage = var.combined_data_storage_gb
          io_limits = {
            read_iops  = var.combined_read_iops
            write_iops = var.combined_write_iops
          }
          io_reserves = {
            read_iops  = var.combined_read_iops
            write_iops = var.combined_write_iops
          }
        },
        {
          name    = "metadata"
          storage = var.combined_metadata_storage_gb
          io_limits = {
            read_iops  = var.combined_read_iops
            write_iops = var.combined_write_iops
          }
          io_reserves = {
            read_iops  = var.combined_read_iops
            write_iops = var.combined_write_iops
          }
        }
      ]
    }
  ] : var.mode == "separated" ? [
    # Separated mode: broker and controller components
    {
      component     = var.broker_component_name
      replicas      = var.broker_replicas
      storage_class = "apelocal-rawdisk-xfs"
      class_code    = var.broker_class_code
      
      volumes = [
        {
          name    = "data"
          storage = var.broker_data_storage_gb
          io_limits = {
            read_iops  = var.broker_read_iops
            write_iops = var.broker_write_iops
          }
          io_reserves = {
            read_iops  = var.broker_read_iops
            write_iops = var.broker_write_iops
          }
        }
      ]
    },
    {
      component     = var.controller_component_name
      replicas      = var.controller_replicas
      storage_class = "apelocal-rawdisk-xfs"
      class_code    = var.controller_class_code
      
      volumes = [
        {
          name    = "metadata"
          storage = var.controller_metadata_storage_gb
          io_limits = {
            read_iops  = var.controller_read_iops
            write_iops = var.controller_write_iops
          }
          io_reserves = {
            read_iops  = var.controller_read_iops
            write_iops = var.controller_write_iops
          }
        }
      ]
    }
  ] : [
    # withZookeeper mode: only broker component
    {
      component     = var.broker_component_name
      replicas      = var.broker_replicas
      storage_class = "apelocal-rawdisk-xfs"
      class_code    = "kafka.${var.mode}.kafka-broker.1c1g.general"
      
      volumes = [
        {
          name    = "data"
          storage = var.broker_data_storage_gb
          io_limits = {
            read_iops  = var.broker_read_iops
            write_iops = var.broker_write_iops
          }
          io_reserves = {
            read_iops  = var.broker_read_iops
            write_iops = var.broker_write_iops
          }
        },
        {
          name    = "metadata"
          storage = var.controller_metadata_storage_gb
          io_limits = {
            read_iops  = var.broker_read_iops
            write_iops = var.broker_write_iops
          }
          io_reserves = {
            read_iops  = var.broker_read_iops
            write_iops = var.broker_write_iops
          }
        }
      ]
    }
  ]

  param_tpls = []

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
