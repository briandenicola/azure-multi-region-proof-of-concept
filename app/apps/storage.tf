data "azurerm_storage_account" "this" {
  name                = local.storage_name
  resource_group_name = local.apps_rg_name
}