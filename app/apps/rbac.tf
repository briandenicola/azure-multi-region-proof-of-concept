resource "azurerm_role_assignment" "acr_pull" {
  scope                            = data.azurerm_container_registry.cqrs_acr.id
  role_definition_name             = "ACRPull"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "secrets" {
  scope                            = data.azurerm_key_vault.cqrs_region.id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "certs" {
  scope                            = data.azurerm_key_vault.cqrs_region.id
  role_definition_name             = "Key Vault Certificates Officer"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "eventhub_data_receiver" {
  scope                            = data.azurerm_key_vault.cqrs_region.id
  role_definition_name             = "Azure Event Hubs Data Receiver"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "eventhub_data_sender" {
  scope                            = data.azurerm_key_vault.cqrs_region.id
  role_definition_name             = "Azure Event Hubs Data Sender"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "metrics_publisher" {
  scope                            = data.azurerm_key_vault.cqrs_region.id
  role_definition_name             = "Monitoring Metrics Publisher"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "metrics_publisher" {
  scope                            = data.azurerm_key_vault.cqrs_region.id
  role_definition_name             = "Monitoring Metrics Publisher"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}


resource "azurerm_role_assignment" "administrator" {
  scope                = data.azurerm_key_vault.cqrs_region.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}
