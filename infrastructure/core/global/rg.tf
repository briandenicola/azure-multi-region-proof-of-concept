resource "azurerm_resource_group" cqrs_global {
  name     = local.rg_name
  location = element(var.locations, 0)

  tags     = {
    Application = "azure-multi-region-proof-of-concept"
    AppName     = var.app_name
    Components  = "Front Door, Azure Monitor, CosmosDB, Azure Contatiner Registry, API Management, Azure Static WebApp"
    DeployedOn  = timestamp()
  }
}

resource "azurerm_resource_group" cqrs_appgw {
  name     = local.appgw_rg_name
  location = element(var.locations, 0)

  tags     = {
    Application = "azure-multi-region-proof-of-concept"
    AppName     = var.app_name
    Components  = "Azure App Gateway"
    DeployedOn  = timestamp()
  }
}