locals {
  rg_name                   = "${var.app_name}_global_rg"
  acr_name                  = "${replace(var.app_name, "-", "")}acr"
  db_name                   = "${var.app_name}-cosmosdb"
  ai_name                   = "${var.app_name}-ai"
  la_name                   = "${var.app_name}-logs"
  cosmosdb_database_name    = "AesKeys"
  cosmosdb_collections_name = "Items"
}
