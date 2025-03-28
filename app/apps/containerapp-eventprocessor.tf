resource "azurerm_container_app" "eventprocessor" {
  depends_on = [ 
    azurerm_key_vault_secret.cosmosdb_connection_string,
    azurerm_key_vault_secret.app_insights_connection_string
  ]
  
  name                         = local.app_eventprocessor_name 
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
      name   = local.app_eventprocessor_name
      image  = local.app_eventprocessor_image
      cpu    = 0.5
      memory = "1Gi"

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
        value = "CommandProcessing"
      }
      env {
        name  = "FUNCTIONS_WORKER_RUNTIME"
        value = "dotnet-isolated"
      }
      
      env {
        name  = "FUNCTIONS_EXTENSION_VERSION"
        value = "~4"
      }

      env {
        name  = "LEASE_COLLECTION_PREFIX"
        value = var.location
      }

      env {
        name  = "EVENTHUB_CONNECTIONSTRING__credential"
        value = "managedidentity"
      }

      env {
        name  = "EVENTHUB_CONNECTIONSTRING__clientId"
        value = azurerm_user_assigned_identity.app_identity.client_id
      }

      env {
        name  = "EVENTHUB_CONNECTIONSTRING__fullyQualifiedNamespace"
        value = "${local.eventhub_namespace_name}.servicebus.windows.net" 
      }

      env {
        name  = "AzureWebJobsStorage__accountName"
        value = data.azurerm_storage_account.cqrs.name
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
        value = data.azurerm_storage_account.cqrs.primary_queue_endpoint
      }

      env {
        name  = "AzureWebJobsStorage__tableServiceUri"
        value = data.azurerm_storage_account.cqrs.primary_table_endpoint
      }

      env {
        name  = "AzureWebJobsStorage__blobServiceUri"
        value = data.azurerm_storage_account.cqrs.primary_blob_endpoint
      }     
    }

    max_replicas = 15
    min_replicas = 1
  
    # Terraform does not support custom scale rules with managed identity yet.
    # custom_scale_rule {
    #   name              = "eventprocessor"
    #   custom_rule_type  = "azure-eventhub"
    #   metadata = {
    #     minReplica         = 0
    #     maxReplica         = 15
    #     cooldownPeriod     = 120
    #     pollingInterval    = 15
    #     consumerGroup      = "eventsfunction"
    #     checkpointStrategy = "azureFunction"
    #     connectionFromEnv  = "EVENTHUB_CONNECTIONSTRINGSTRING"
    #     storageConnectionFromEnv : "AzureWebJobsStorage"
    #   }
    # }
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
