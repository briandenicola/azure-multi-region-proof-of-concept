resource "random_integer" "vnet_cidr" {
  min = 10
  max = 250
}
locals {
  infra_rg_name                        = "${var.app_name}_${var.location}_infra_rg"
  apps_rg_name                         = "${var.app_name}_${var.location}_apps_rg"
  vnet_rg_name                         = "${var.app_name}_${var.location}_vnet_rg"
  dns_rg_name                          = "${var.app_name}_${var.location}_dns_zones_rg"
  global_rg_name                       = "${var.app_name}_global_rg"
  acr_name                             = "${replace(var.app_name, "-", "")}acr"
  safe_name                            = substr("${replace(var.app_name, "-", "")}${var.location}", 0, 20)
  db_name                              = "${var.app_name}-cosmosdb"
  la_name                              = "${var.app_name}-logs"
  ai_name                              = "${var.app_name}-ai"
  regional_name                        = "${var.app_name}-${var.location}"
  storage_name                         = "${local.safe_name}sa"
  kv_name                              = "${local.safe_name}kv"
  redis_name                           = "${local.regional_name}-cache"
  eventhub_namespace_name              = "${local.regional_name}-eventhubs"
  aca_name                             = "${local.regional_name}-env"
  vnet_name                            = "${local.regional_name}-vnet"
  nsg_name                             = "${local.regional_name}-nsg"
  route_table_name                     = "${local.regional_name}-routetable"  
  firewall_name                        = "${local.regional_name}-fw"
  eventhub_name                        = "events"
  azurerm_eventhub_consumer_group_name = "eventsfunction"
  workload_profile_name                = "default"
  workload_profile_size                = "D4"
  vnet_cidr                            = cidrsubnet("10.0.0.0/8", 8, random_integer.vnet_cidr.result)
  pe_subnet_cidr                       = cidrsubnet(local.vnet_cidr, 8, 1)
  compute_subnet_cidr                  = cidrsubnet(local.vnet_cidr, 8, 2)
  fw_subnet_cidr                       = cidrsubnet(local.vnet_cidr, 8, 3)
  apim_subnet_cidr                     = cidrsubnet(local.vnet_cidr, 8, 4)
  appgw_subnet_cidr                    = cidrsubnet(local.vnet_cidr, 8, 5)
  databricks_private_subnet_cidr       = cidrsubnet(local.vnet_cidr, 8, 6)
  databricks_public_subnet_cidr        = cidrsubnet(local.vnet_cidr, 8, 7)
  nodes_subnet_cidr                    = cidrsubnet(local.vnet_cidr, 8, 8)
}
