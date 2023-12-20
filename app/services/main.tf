terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

locals {
  regional_name                  = "${var.app_name}-${var.location}"
  rg_name                        = "${var.app_name}_${var.location}_rg"
  global_rg_name                 = "${var.app_name}_global_rg"
  ai_name                        = "${var.app_name}-ai"
  acr_name                       = "${replace(var.app_name, "-", "")}acr.azurecr.io"
  aca_name                       = "${local.regional_name}-env"
  kv_name                        = "${local.regional_name}-kv"
  db_name                        = "${var.app_name}-cosmosdb"
  eventhub_namespace_name        = "${local.regional_name}-ehns"
  redis_name                     = "${local.regional_name}-cache"
  storage_name                   = "${replace(var.app_name, "-", "")}${var.location}sa"
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
