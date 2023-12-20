resource "azurerm_container_app" "changefeedprocessor" {
  name                         = "changefeedprocessor"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.cqrs_regional.name
  revision_mode                = "Single"
  workload_profile_name        = "default"

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.app_identity
    ]
  }

  registry {
    server  = local.acr_name
    identity = var.app_identity
  }

  template { 
    container {
      name   = "changefeedprocessor"
      image  = local.changefeedprocessor_image
      cpu    = 1
      memory = "0.5Gi"
      
      env {
        name = "AzureFunctionsJobHost__functions__0"
        value = "CosmosChangeFeedProcessor"
      }
    }
  }
}

resource "azapi_update_resource" "changefeedprocessor_secrets" {
  depends_on = [ 
    azurerm_key_vault_secret.eventhub_connection_string,
    azurerm_key_vault_secret.cosmosdb_connection_string,
    azurerm_key_vault_secret.redis_connection_string,
    azurerm_key_vault_secret.storage_connection_string
  ]

  type        = "Microsoft.App/containerApps@2023-05-01"
  resource_id = azurerm_container_app.changefeedprocessor.id

  body = jsonencode({
    properties = {
      configuration = {
        secrets = [
          {
            keyVaultUrl = azurerm_key_vault_secret.eventhub_connection_string.id
            name = local.EVENTHUB_CONNECTIONSTRING
            identity = var.app_identity
          },
          {
            keyVaultUrl = azurerm_key_vault_secret.cosmosdb_connection_string.id
            name = local.COSMOSDB_CONNECTIONSTRING
            identity = var.app_identity
          },
          {
            keyVaultUrl = azurerm_key_vault_secret.redis_connection_string.id
            name = local.REDISCACHE_CONNECTIONSTRING
            identity = var.app_identity
          },
          {
            keyVaultUrl = azurerm_key_vault_secret.storage_connection_string.id
            name = local.AzureWebJobsStorage
            identity = var.app_identity
          }
        ]
      }
    }
  })
}
