terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

locals {
  regional_name                 = "${var.app_name}-${var.location}"
  infra_rg_name                 = "${var.app_name}_${var.location}_infra_rg"
  apps_rg_name                  = "${var.app_name}_${var.location}_apps_rg"
  global_rg_name                = "${var.app_name}_global_rg"
  ai_name                       = "${var.app_name}-ai"
  logs_name                     = "${var.app_name}-logs"
  acr_name                      = "${replace(var.app_name, "-", "")}acr"
  acr_fqdn                      = "${local.acr_name}.azurecr.io"
  safe_name                     = substr("${replace(var.app_name, "-", "")}${var.location}", 0, 20)
  aca_name                      = "${local.regional_name}-env"
  storage_name                  = "${local.safe_name}sa"
  kv_name                       = "${local.safe_name}kv"
  app_identity                  = "${local.regional_name}-app-identity"
  db_name                       = "${var.app_name}-cosmosdb"
  eventhub_namespace_name       = "${local.regional_name}-eventhubs"
  event_hub_name                = "events"
  redis_name                    = "${local.regional_name}-cache"
  workload_profile_name         = "default"
  COSMOSDB_CONNECTIONSTRING     = "cosmosdb-connection-string"
  APPINSIGHTS_CONNECTION_STRING = "appinsights-connection-string"

  api_image                     = "${local.acr_fqdn}/cqrs/api:${var.commit_version}"
  eventprocessor_image          = "${local.acr_fqdn}/cqrs/eventprocessor:${var.commit_version}"
  changefeedprocessor_image     = "${local.acr_fqdn}/cqrs/changefeedprocessor:${var.commit_version}"
  utils_image                   = "bjd145/utils:3.20"
}
