terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

locals {
  safe_name                     = substr("${replace(var.app_name, "-", "")}${var.location}", 0, 20)

  regional_name                 = "${var.app_name}-${var.location}"
  infra_rg_name                 = "${var.app_name}_${var.location}_infra_rg"
  apps_rg_name                  = "${var.app_name}_${var.location}_apps_rg"
  global_rg_name                = "${var.app_name}_global_rg"
  ai_name                       = "${var.app_name}-ai"
  logs_name                     = "${var.app_name}-logs"
  
  aca_name                      = "${local.regional_name}-env"
  acr_name                      = "${replace(var.app_name, "-", "")}acr"
  storage_name                  = "${local.safe_name}sa"
  kv_name                       = "${local.safe_name}kv"
  db_name                       = "${var.app_name}-cosmosdb"
  eventhub_namespace_name       = "${local.regional_name}-eventhubs"
  redis_name                    = "${local.regional_name}-cache"

  workload_profile_name         = "default"
  event_hub_name                = "events"
  
  COSMOSDB_CONNECTIONSTRING     = "cosmosdb-connection-string"
  APPINSIGHTS_CONNECTION_STRING = "appinsights-connection-string"
  
  utils_image                   = "bjd145/utils:3.20"
  acr_fqdn                      = "${local.acr_name}.azurecr.io"
  app_identity                  = "${local.regional_name}-app-identity"
  app_eventprocessor_name       = "eventprocessor"
  app_eventprocessor_image      = "${local.acr_fqdn}/cqrs/${app_eventprocessor_name}:${var.commit_version}"

  app_changefeedprocessor_name  = "changefeedprocessor"
  app_changefeedprocessor_image = "${local.acr_fqdn}/cqrs/${app_changefeedprocessor_name}:${var.commit_version}"

  app_api_name                  = "api"
  app_api_image                 = "${local.acr_fqdn}/cqrs/${app_api_name}:${var.commit_version}"
  app_api_custom_domain_name    = var.ingress_domain_name
}
