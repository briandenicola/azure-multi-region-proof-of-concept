resource "azurerm_resource_group" "regional_apps" {
  name     = local.apps_rg_name
  location = var.location
  tags = {
    Application = var.tags
    AppName     = var.app_name
    Components  = "Container Apps, KeyVault, Managed Identity "
    Methodology = "CQR Patterns, Event-Driven Architecture, Microservices"
    DeployedOn  = timestamp()
  }
}