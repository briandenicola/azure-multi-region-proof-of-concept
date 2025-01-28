data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "http" "myip" {
  url = "http://checkip.amazonaws.com/"
}

data "azurerm_container_app_environment" "this" {
  name                = local.aca_name
  resource_group_name = local.infra_rg_name
}

data "azurerm_container_app_environment_certificate" "this" {
  name                         = replace(var.custom_domain, ".", "-")
  container_app_environment_id = data.azurerm_container_app_environment.this.id
}

data "azurerm_cosmosdb_account" "cqrs" {
  name                = local.db_name
  resource_group_name = local.global_rg_name
}

data "azurerm_application_insights" "cqrs" {
  name                = local.ai_name
  resource_group_name = local.global_rg_name
}

data "azurerm_container_registry" "cqrs" {
  name                = local.acr_name
  resource_group_name = local.global_rg_name
}

data "azurerm_redis_cache" "cqrs" {
  name                = local.redis_name
  resource_group_name = local.apps_rg_name
}

data "azurerm_eventhub_namespace" "cqrs" {
  name                = local.eventhub_namespace_name
  resource_group_name = local.apps_rg_name
}

data "azurerm_storage_account" "cqrs" {
  name                = local.storage_name
  resource_group_name = local.apps_rg_name
}

data "azurerm_key_vault" "cqrs" {
  name                = local.kv_name
  resource_group_name = local.apps_rg_name
}

