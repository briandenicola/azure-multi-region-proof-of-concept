resource azurerm_resource_group cqrs_region {
  name     = local.rg_name
  location = var.location
  tags = {
    Application = "cqrs"
    Version     = var.app_name
    Components  = "regional"
    DeployedOn  = timestamp()
  }
}