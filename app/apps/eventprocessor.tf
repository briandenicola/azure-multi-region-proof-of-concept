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
    server   = local.acr_fqdn
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
        name        = "COSMOSDB_CONNECTIONSTRING"
        secret_name = local.COSMOSDB_CONNECTIONSTRING
      }
      env {
        name        = "APPINSIGHTS_CONNECTION_STRING"
        secret_name = local.APPINSIGHTS_CONNECTION_STRING
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
