data "azurerm_eventhub_namespace" "this" {
  name                = local.eventhub_namespace_name
  resource_group_name = local.apps_rg_name
}

