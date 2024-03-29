resource azurerm_resource_group cqrs_region {
  name     = local.infra_rg_name
  location = var.location
  tags = {
    Application = "azure-multi-region-proof-of-concept"
    AppName     = var.app_name
    Components  = "Azure Firewall, Azure Container Apps Environment, Virutal Network, Private DNS Zones, Private Endpoints"
    DeployedOn  = timestamp()
  }
}

resource azurerm_resource_group cqrs_apps {
  name     = local.apps_rg_name
  location = var.location
  tags = {
    Application = "azure-multi-region-proof-of-concept"
    AppName     = var.app_name
    Components  = "Container Apps, KeyVault, Redis, Azure Storage, Event Hub"
    DeployedOn  = timestamp()
  }
}