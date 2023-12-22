resource "azurerm_container_app" "changefeedprocessor" {
  lifecycle {
    ignore_changes = [
      secret,
      template[0].container[0].env
    ]
  }

  name                         = "changefeedprocessor"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.cqrs_regional.name
  revision_mode                = "Single"
  workload_profile_name        = local.workload_profile_name

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
    }
  }
}

resource "azapi_update_resource" "changefeedprocessor_secrets" {
  depends_on = [ 
    azurerm_container_app.changefeedprocessor,
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
          },
          {
            keyVaultUrl = azurerm_key_vault_secret.app_insights_connection_string.id
            name = local.APPINSIGHTS_INSTRUMENTATIONKEY
            identity = var.app_identity
          }
        ]
      },
      template = {
        containers = [{
          name = "changefeedprocessor",
          env = [
            {
              name = "AzureFunctionsJobHost__functions__0"
              value = "CosmosChangeFeedProcessor"
            },
            {
              name = "FUNCTIONS_WORKER_RUNTIME"
              value = "dotnet"
            },
            {
              name = "EVENTHUB_CONNECTIONSTRING"
              secretRef = local.EVENTHUB_CONNECTIONSTRING
            },
            {
              name = "COSMOSDB_CONNECTIONSTRING"
              secretRef = local.COSMOSDB_CONNECTIONSTRING
            },
            {
              name = "REDISCACHE_CONNECTIONSTRING"
              secretRef = local.REDISCACHE_CONNECTIONSTRING
            },
            {
              name = "APPINSIGHTS_INSTRUMENTATIONKEY"
              secretRef = local.APPINSIGHTS_INSTRUMENTATIONKEY
            },
            {
              name = "AzureWebJobsStorage"
              secretRef = local.AzureWebJobsStorage
            }
          ]
        }]
      }
    }
  })
}
