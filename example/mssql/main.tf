terraform {
  required_providers {
    kbcloud = {
      source  = "registry.terraform.io/apecloud/kbcloud"
      version = "2.2.0-beta.2"
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
  # https_skip_verify = var.https_skip_verify
}
resource "kbcloud_cluster" "my_mssql" {
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

  extra = {
    certificate    = {
      custom = var.certificate_custom
    }
    collation      = var.collation
    defaultDBName  = var.default_db_name
    productEdition = var.product_edition
  }

  maintaince_window = {
    start_hour = var.maintenance_start_hour
    end_hour   = var.maintenance_end_hour
    weekdays   = var.maintenance_weekdays
  }

  components = [
    {
      component = var.component_name
      replicas  = var.replicas
      volumes = [
        {
          name    = "data"
          storage = var.storage_size_gb # GB
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
      storage_class = var.storage_class
      class_code    = var.class_code
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
    auto_backup_method          = var.auto_backup_method
    backup_repo                 = var.backup_repo
    retention_period            = var.retention_period
    retention_policy            = var.retention_policy
    cron_expression             = var.cron_expression
    snapshot_volumes            = var.snapshot_volumes
    pitr_enabled                = var.pitr_enabled
    continuous_backup_method    = var.continuous_backup_method
    incremental_backup_enabled  = var.incremental_backup_enabled
    incremental_cron_expression = var.incremental_cron_expression
  }
}
