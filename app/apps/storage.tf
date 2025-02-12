data "azurerm_storage_account" "cqrs" {
  name                = local.storage_name
  resource_group_name = local.apps_rg_name
}