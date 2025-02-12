data "azurerm_eventhub_namespace" "cqrs" {
  name                = local.eventhub_namespace_name
  resource_group_name = local.apps_rg_name
}

