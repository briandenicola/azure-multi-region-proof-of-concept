resource "azurerm_container_app" "eventprocessor" {
  
  lifecycle {
    ignore_changes = [
      secret,
      template[0].container[0].env
    ]
  }

  name                         = "eventprocessor"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.cqrs_apps.name
  revision_mode                = "Single"
  workload_profile_name        = local.workload_profile_name

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.app_identity
    ]
  }

  registry {
    server   = local.acr_name
    identity = var.app_identity
  }

  template {
    container {
      name   = "eventprocessor"
      image  = local.eventprocessor_image
      cpu    = 0.5
      memory = "1Gi"
    }

    max_replicas = 15
    min_replicas = 0

    custom_scale_rule {
      name = "eventprocessor"
      custom_rule_type = "azure-eventhub"
      metadata = {
        minReplica = 0
        maxReplica = 15
        cooldownPeriod  = 120
        pollingInterval = 15
        consumerGroup   = "eventsfunction"
        checkpointStrategy = "azureFunction"
        connectionFromEnv = "EVENTHUB_CONNECTIONSTRING"
        storageConnectionFromEnv: "AzureWebJobsStorage"
      }
    }
  }
}

resource "azapi_update_resource" "eventprocessor_secrets" {
  depends_on = [
    azurerm_container_app.eventprocessor,
    azurerm_key_vault_secret.eventhub_connection_string,
    azurerm_key_vault_secret.cosmosdb_connection_string,
    azurerm_key_vault_secret.redis_connection_string,
    azurerm_key_vault_secret.storage_connection_string
  ]

  type        = "Microsoft.App/containerApps@2023-05-01"
  resource_id = azurerm_container_app.eventprocessor.id

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
          name = "eventprocessor",
          env = [
            {
              name = "AzureFunctionsJobHost__functions__0"
              value = "CommandProcessing"
            },
            {
              name = "FUNCTIONS_WORKER_RUNTIME"
              value = "dotnet"
            },
            {
              name = "LEASE_COLLECTION_PREFIX"
              value = var.location
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
