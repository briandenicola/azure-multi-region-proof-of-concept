resource azurerm_user_assigned_identity app_identity {
  name                = local.app_identity
  resource_group_name = local.apps_rg_name
  location            = var.location
}