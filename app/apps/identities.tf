resource azurerm_user_assigned_identity app_identity {
  name                = local.app_identity
  resource_group_name = data.azurerm_resource_group.cqrs_global.name
  location            = data.azurerm_resource_group.cqrs_global.location
}

resource azurerm_role_assignment acr_pullrole_node {
  scope                            = data.azurerm_container_registry.cqrs_acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}