resource azurerm_resource_group cqrs_region {
  name     = local.infra_rg_name
  location = var.location
  tags = {
    Application = "cqrs"
    Version     = var.app_name
    Components  = "regional"
    DeployedOn  = timestamp()
  }
}

resource azurerm_resource_group cqrs_apps {
  name     = local.apps_rg_name
  location = var.location
  tags = {
    Application = "cqrs"
    Version     = var.app_name
    Components  = "Container Apps"
    DeployedOn  = timestamp()
  }
}