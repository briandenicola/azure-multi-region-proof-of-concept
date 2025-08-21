resource "azurerm_container_app" "changefeedprocessor" {
  depends_on = [ 
    azurerm_key_vault_secret.cosmosdb_connection_string,
    azurerm_key_vault_secret.app_insights_connection_string
  ]
  name                         = local.app_changefeedprocessor_name
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.regional_apps.name
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
      name   = local.app_changefeedprocessor_name
      image  = local.app_changefeedprocessor_image
      cpu    = 1
      memory = "0.5Gi"

      env {
        name        = "COSMOSDB_CONNECTIONSTRING"
        secret_name = local.COSMOSDB_CONNECTIONSTRING
      }
      env {
        name        = "APPINSIGHTS_CONNECTION_STRING"
        secret_name = local.APPINSIGHTS_CONNECTION_STRING
      }

      env {
        name  = "AzureFunctionsJobHost__functions__0"
        value = "CosmosChangeFeedProcessor"
      }
      env {
        name  = "FUNCTIONS_WORKER_RUNTIME"
        value = "dotnet-isolated"
      }

      env {
        name  = "CACHE_ENABLED"
        value = var.use_cache
      }

      env {
        name  = "redisConnectionString__redisHostName"
        value = "${local.redis_name}.${var.location}.redis.azure.net:10000"
      }

      env {
        name  = "redisConnectionString__principalId"
        value = azurerm_user_assigned_identity.app_identity.principal_id
      }

      env {
        name  = "redisConnectionString__clientId"
        value = azurerm_user_assigned_identity.app_identity.client_id
      }

      env {
        name  = "AzureWebJobsStorage__accountName"
        value = data.azurerm_storage_account.this.name
      }

      env {
        name  = "AzureWebJobsStorage__credential"
        value = "managedidentity"
      }
      env {
        name  = "AzureWebJobsStorage__clientId"
        value = azurerm_user_assigned_identity.app_identity.client_id
      }
      env {
        name  = "AzureWebJobsStorage__queueServiceUri"
        value = data.azurerm_storage_account.this.primary_queue_endpoint
      }

      env {
        name  = "AzureWebJobsStorage__tableServiceUri"
        value = data.azurerm_storage_account.this.primary_table_endpoint
      }

      env {
        name  = "AzureWebJobsStorage__blobServiceUri"
        value = data.azurerm_storage_account.this.primary_blob_endpoint
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
