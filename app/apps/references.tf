data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "http" "myip" {
  url = "http://checkip.amazonaws.com/"
}

data "azurerm_storage_account" "this" {
  name                = local.storage_name
  resource_group_name = local.apps_rg_name
}

data "azurerm_application_insights" "this" {
  name                = local.ai_name
  resource_group_name = local.global_rg_name
}

data "azurerm_log_analytics_workspace" "this" {
  name                = local.logs_name
  resource_group_name = local.global_rg_name
}

data "azurerm_eventhub_namespace" "this" {
  name                = local.eventhub_namespace_name
  resource_group_name = local.apps_rg_name
}

data "azurerm_cosmosdb_account" "this" {
  name                = local.db_name
  resource_group_name = local.global_rg_name
}

data "azurerm_container_registry" "this" {
  name                = local.acr_name
  resource_group_name = local.global_rg_name
}

data "azurerm_subnet" "pe" {
  name                 = local.pe_subnet_name
  virtual_network_name = local.vnet_name
  resource_group_name  = local.vnet_rg_name
}

data azurerm_private_dns_zone privatelink_vaultcore_azure_net {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.dns_rg_name
}

data "azurerm_container_app_environment" "this" {
  name                = local.aca_name
  resource_group_name = local.infra_rg_name
}

data "azurerm_container_app_environment_certificate" "this" {
  name                         = replace(var.custom_domain, ".", "-")
  container_app_environment_id = data.azurerm_container_app_environment.this.id
}