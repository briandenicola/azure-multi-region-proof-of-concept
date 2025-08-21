resource "azurerm_resource_group" "regional_dns" {
  name     = local.dns_rg_name
  location = var.location
  tags = {
    Application = var.tags
    AppName     = var.app_name
    Components  = "Private DNS Zones"
    Methodology = "CQR Patterns, Event-Driven Architecture, Microservices"
    DeployedOn  = timestamp()
  }
}

resource "azurerm_resource_group" "regional_infra" {
  name     = local.infra_rg_name
  location = var.location
  tags = {
    Application = var.tags
    AppName     = var.app_name
    Components  = "Azure Firewall, Azure Container Apps Environment, App Gateway, Redis, Managed Redis, Azure Storage, Event Hub"
    Methodology = "CQR Patterns, Event-Driven Architecture, Microservices"
    DeployedOn  = timestamp()
  }
}

resource "azurerm_resource_group" "regional_network" {
  name     = local.vnet_rg_name
  location = var.location
  tags = {
    Application = var.tags
    AppName     = var.app_name
    Components  = "Virtual Network, Private Endpoints"
    Methodology = "CQR Patterns, Event-Driven Architecture, Microservices"
    DeployedOn  = timestamp()
  }
}
