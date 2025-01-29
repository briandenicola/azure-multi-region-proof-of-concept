resource "azurerm_container_app" "changefeedprocessor" {
  lifecycle {
    ignore_changes = [
      secret,
      template[0].container[0].env
    ]
  }

  name                         = "changefeedprocessor"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = local.apps_rg_name
  revision_mode                = "Single"
  workload_profile_name        = local.workload_profile_name

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.app_identity.id
    ]
  }

  registry {
    server   = local.acr_fqdn
    identity = azurerm_user_assigned_identity.app_identity.id
  }

  template {
    container {
      name   = "changefeedprocessor"
      image  = local.changefeedprocessor_image
      cpu    = 1
      memory = "0.5Gi"

      env {
        name  = "AzureFunctionsJobHost__functions__0"
        value = "CosmosChangeFeedProcessor"
      }
      env {
        name  = "FUNCTIONS_WORKER_RUNTIME"
        value = "dotnet"
      }
      env {
        name        = "COSMOSDB_CONNECTIONSTRING"
        secret_name = local.COSMOSDB_CONNECTIONSTRING
      }
      env {
        name        = "APPINSIGHTS_CONNECTION_STRING"
        secret_name = local.APPINSIGHTS_CONNECTION_STRING      
      }
    }

    max_replicas = 1
    min_replicas = 1
  }

  secret {
    key_vault_secret_id = azurerm_key_vault_secret.cosmosdb_connection_string.id
    name                = local.COSMOSDB_CONNECTIONSTRING
    identity            = azurerm_user_assigned_identity.app_identity.id
  }
  secret {
    key_vault_secret_id = azurerm_key_vault_secret.app_insights_connection_string.id
    name                = local.APPINSIGHTS_CONNECTION_STRING
    identity            = azurerm_user_assigned_identity.app_identity.id
  }
}
