
locals {
  rg_name                   = "${var.app_name}_global_rg"
  ui_rg_name                = "${var.app_name}_ui_rg"
  appgw_rg_name             = "${var.app_name}_appgw_rg"
  acr_name                  = "${replace(var.app_name, "-", "")}acr"
  db_name                   = "${var.app_name}-cosmosdb"
  ai_name                   = "${var.app_name}-ai"
  la_name                   = "${var.app_name}-logs"
  
  cosmosdb_database_name    = "AesKeys"
  cosmosdb_collections_name = "Items"
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}
