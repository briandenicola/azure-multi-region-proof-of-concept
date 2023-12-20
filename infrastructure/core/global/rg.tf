resource "azurerm_resource_group" cqrs_global {
  name     = local.rg_name
  location = element(var.locations, 0)

  tags     = {
    Application = "cqrs"
    Version     = var.app_name
    Components  = "global"
    DeployedOn  = timestamp()
  }
  
}