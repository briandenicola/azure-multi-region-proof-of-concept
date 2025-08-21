resource "azurerm_user_assigned_identity" "app_identity" {
  name                = local.app_identity
  resource_group_name = azurerm_resource_group.regional_apps.name
  location            = var.location
}
