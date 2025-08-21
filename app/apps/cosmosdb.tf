data "azurerm_cosmosdb_account" "this" {
  name                = local.db_name
  resource_group_name = local.global_rg_name
}
