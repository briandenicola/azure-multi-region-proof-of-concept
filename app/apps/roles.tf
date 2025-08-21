resource "azurerm_role_assignment" "acr_pull" {
  scope                            = data.azurerm_container_registry.this.id
  role_definition_name             = "ACRPull"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "secrets" {
  scope                            = azurerm_key_vault.this.id
  role_definition_name             = "Key Vault Secrets User"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "certs" {
  scope                            = azurerm_key_vault.this.id
  role_definition_name             = "Key Vault Certificates Officer"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "eventhub_data_receiver" {
  scope                            = data.azurerm_eventhub_namespace.this.id
  role_definition_name             = "Azure Event Hubs Data Receiver"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "eventhub_data_sender" {
  scope                            = data.azurerm_eventhub_namespace.this.id
  role_definition_name             = "Azure Event Hubs Data Sender"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "eventhub_data_owenr" {
  scope                            = data.azurerm_eventhub_namespace.this.id
  role_definition_name             = "Azure Event Hubs Data Owner"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "metrics_publisher_app_insights" {
  scope                            = data.azurerm_application_insights.this.id
  role_definition_name             = "Monitoring Metrics Publisher"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "metrics_publisher_log_analytics" {
  scope                            = data.azurerm_log_analytics_workspace.this.id
  role_definition_name             = "Monitoring Metrics Publisher"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "storage_blob_owner" {
  scope                            = data.azurerm_storage_account.this.id
  role_definition_name             = "Storage Blob Data Owner"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "storage_account_contributor" {
  scope                            = data.azurerm_storage_account.this.id
  role_definition_name             = "Storage Account Contributor"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "azurerm_queue_account" {
  scope                            = data.azurerm_storage_account.this.id
  role_definition_name             = "Storage Queue Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.app_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "administrator" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}
