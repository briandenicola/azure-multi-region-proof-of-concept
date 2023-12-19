resource azurerm_user_assigned_identity app_identity {
  name                = local.workload_identity
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = azurerm_resource_group.cqrs_region.location
}
