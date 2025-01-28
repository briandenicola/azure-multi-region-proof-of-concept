resource "azurerm_resource_group" "cqrs_global" {
  name     = local.rg_name
  location = element(var.locations, 0)

  tags = {
    Application = var.tags
    AppName     = var.app_name
    Components  = "Front Door, Azure Monitor, CosmosDB, Azure Container Registry, API Management, Azure Redis, "
    DeployedOn  = timestamp()
  }
}

resource "azurerm_resource_group" "cqrs_appgw" {
  count               = var.deploying_externally ? 1 : 0
  name     = local.appgw_rg_name
  location = element(var.locations, 0)

  tags = {
    Application = var.tags
    AppName     = var.app_name
    Components  = "Azure App Gateway"
    DeployedOn  = timestamp()
  }
}

resource "azurerm_resource_group" "cqrs_ui" {
  count               = var.deploying_externally ? 1 : 0
  name     = local.ui_rg_name
  location = element(var.locations, 0)

  tags = {
    Application = var.tags
    AppName     = var.app_name
    Components  = "Azure Static WebApp"
    DeployedOn  = timestamp()
  }
}
