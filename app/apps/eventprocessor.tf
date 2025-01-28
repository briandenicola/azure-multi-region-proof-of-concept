resource "azurerm_container_app" "eventprocessor" {

  lifecycle {
    ignore_changes = [
      secret,
      template[0].container[0].env
    ]
  }

  name                         = "eventprocessor"
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
    server   = local.acr_name
    identity = azurerm_user_assigned_identity.app_identity.id
  }

  template {
    container {
      name   = "eventprocessor"
      image  = local.eventprocessor_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AzureFunctionsJobHost__functions__0"
        value = "CommandProcessing"
      }
      env {
        name  = "FUNCTIONS_WORKER_RUNTIME"
        value = "dotnet"
      }
      env {
        name  = "LEASE_COLLECTION_PREFIX"
        value = var.location
      }
      env {
        name        = "EVENTHUB_CONNECTIONSTRING"
        secret_name = local.EVENTHUB_CONNECTIONSTRING
      }
      env {
        name        = "COSMOSDB_CONNECTIONSTRING"
        secret_name = local.COSMOSDB_CONNECTIONSTRING
      }
      env {
        name        = "REDISCACHE_CONNECTIONSTRING"
        secret_name = local.REDISCACHE_CONNECTIONSTRING
      }
      env {
        name        = "APPINSIGHTS_INSTRUMENTATIONKEY"
        secret_name = local.APPINSIGHTS_INSTRUMENTATIONKEY
      }
      env {
        name        = "AzureWebJobsStorage"
        secret_name = local.AzureWebJobsStorage
      }
    }

    max_replicas = 15
    min_replicas = 0

    custom_scale_rule {
      name             = "eventprocessor"
      custom_rule_type = "azure-eventhub"
      metadata = {
        minReplica         = 0
        maxReplica         = 15
        cooldownPeriod     = 120
        pollingInterval    = 15
        consumerGroup      = "eventsfunction"
        checkpointStrategy = "azureFunction"
        connectionFromEnv  = "EVENTHUB_CONNECTIONSTRING"
        storageConnectionFromEnv : "AzureWebJobsStorage"
      }
    }
  }

  secret {
    key_vault_secret_id = azurerm_key_vault_secret.eventhub_connection_string.id
    name                = local.EVENTHUB_CONNECTIONSTRING
    identity            = azurerm_user_assigned_identity.app_identity.id
  }
  secret {
    key_vault_secret_id = azurerm_key_vault_secret.cosmosdb_connection_string.id
    name                = local.COSMOSDB_CONNECTIONSTRING
    identity            = azurerm_user_assigned_identity.app_identity.id
  }
  secret {
    key_vault_secret_id = azurerm_key_vault_secret.redis_connection_string.id
    name                = local.REDISCACHE_CONNECTIONSTRING
    identity            = azurerm_user_assigned_identity.app_identity.id
  }
  secret {
    key_vault_secret_id = azurerm_key_vault_secret.storage_connection_string.id
    name                = local.AzureWebJobsStorage
    identity            = azurerm_user_assigned_identity.app_identity.id
  }
  secret {
    key_vault_secret_id = azurerm_key_vault_secret.app_insights_connection_string.id
    name                = local.APPINSIGHTS_INSTRUMENTATIONKEY
    identity            = azurerm_user_assigned_identity.app_identity.id
  }
}
