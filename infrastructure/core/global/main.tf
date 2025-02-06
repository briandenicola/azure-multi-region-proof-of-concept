
locals {
  swa_regions               = ["westus2", "centralus", "eastus2", "westeurope", "eastasia"]
  rg_name                   = "${var.app_name}_global_rg"
  primary_location          = element(var.locations, 0)
  ui_rg_name                = "${var.app_name}_ui_rg"
  appgw_rg_name             = "${var.app_name}_appgw_rg"
  acr_name                  = "${replace(var.app_name, "-", "")}acr"
  db_name                   = "${var.app_name}-cosmosdb"
  ai_name                   = "${var.app_name}-ai"
  la_name                   = "${var.app_name}-logs"
  static_webapp_name        = "${var.app_name}-ui"
  static_webapp_location    = contains(local.swa_regions, local.primary_location) ? local.primary_location : "centralus"
  cosmosdb_database_name    = "AesKeys"
  cosmosdb_collections_name = "Items"
}
