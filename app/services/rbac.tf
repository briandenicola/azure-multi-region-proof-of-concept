resource azurerm_role_assignment secrets {
  scope                            = data.azurerm_key_vault.cqrs_region.id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = var.app_identity_principal_id
  skip_service_principal_aad_check = true
}

resource azurerm_role_assignment certs {
  scope                            = data.azurerm_key_vault.cqrs_region.id
  role_definition_name             = "Key Vault Certificates Officer"
  principal_id                     = var.app_identity_principal_id
  skip_service_principal_aad_check = true
}

resource azurerm_role_assignment administrator {
  scope                            = data.azurerm_key_vault.cqrs_region.id
  role_definition_name             = "Key Vault Administrator"
  principal_id                     = data.azurerm_client_config.current.object_id
}