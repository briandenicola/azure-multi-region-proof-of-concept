terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

locals {
  regional_name                  = "${var.app_name}-${var.location}"
  infra_rg_name                  = "${var.app_name}_${var.location}_infra_rg"
  apps_rg_name                   = "${var.app_name}_${var.location}_apps_rg"
  global_rg_name                 = "${var.app_name}_global_rg"
  ai_name                        = "${var.app_name}-ai"
  acr_name                       = "${replace(var.app_name, "-", "")}acr.azurecr.io"
  aca_name                       = "${local.regional_name}-env"
  kv_name                        = "${replace(var.app_name, "-", "")}${var.location}kv"
  storage_name                   = "${replace(var.app_name, "-", "")}${var.location}sa"
  app_identity                   = "${local.regional_name}-app-identity"
  db_name                        = "${var.app_name}-cosmosdb"
  eventhub_namespace_name        = "${local.regional_name}-ehns"
  event_hub_name                 = "events"
  redis_name                     = "${local.regional_name}-cache"
  workload_profile_name          = "default"
  EVENTHUB_CONNECTIONSTRING      = "eventhub-connectionstring"
  COSMOSDB_CONNECTIONSTRING      = "cosmosdb-connectionstring"
  REDISCACHE_CONNECTIONSTRING    = "rediscache-connectionstring"
  APPINSIGHTS_INSTRUMENTATIONKEY = "appinsights-instrumentationkey"
  AzureWebJobsStorage            = "azurewebjobsstorage"

  api_image                 = "${local.acr_name}/cqrs/api:${var.commit_version}"
  eventprocessor_image      = "${local.acr_name}/cqrs/eventprocessor:${var.commit_version}"
  changefeedprocessor_image = "${local.acr_name}/cqrs/changefeedprocessor:${var.commit_version}"
  utils_image               = "bjd145/utils:3.15"
}
