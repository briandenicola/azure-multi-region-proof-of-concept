resource "azurerm_container_app" "api" {
  lifecycle {
    ignore_changes = [
      template[0].container[0].env
    ]
  }

  name                         = "api"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.cqrs_regional.name
  revision_mode                = "Multiple"
  workload_profile_name        = "default"

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.app_identity
    ]
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = false
    target_port                = 8080
    transport                  = "auto"

    custom_domain {
      certificate_binding_type = "SniEnabled"
      certificate_id           = data.azurerm_container_app_environment_certificate.this.id
      name                     = "api-internal.${var.custom_domain}"
    }

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  registry {
    server   = local.acr_name
    identity = var.app_identity
  }

  template {
    container {
      name   = "api"
      image  = local.api_image
      cpu    = 1
      memory = "0.5Gi"

      liveness_probe {
        path             = "/healthz"
        port             = 8080
        initial_delay    = 3
        interval_seconds = 3
        transport        = "HTTP"
      }
    }
  }
}

resource "azapi_update_resource" "api_secrets" {
  depends_on = [
    azurerm_container_app.api,
    azurerm_key_vault_secret.eventhub_connection_string,
    azurerm_key_vault_secret.cosmosdb_connection_string,
    azurerm_key_vault_secret.redis_connection_string,
    azurerm_key_vault_secret.storage_connection_string
  ]

  type        = "Microsoft.App/containerApps@2023-05-01"
  resource_id = azurerm_container_app.api.id

  body = jsonencode({
    properties = {
      configuration = {
        secrets = [
          {
            keyVaultUrl = azurerm_key_vault_secret.eventhub_connection_string.id
            name        = local.EVENTHUB_CONNECTIONSTRING
            identity    = var.app_identity
          },
          {
            keyVaultUrl = azurerm_key_vault_secret.cosmosdb_connection_string.id
            name        = local.COSMOSDB_CONNECTIONSTRING
            identity    = var.app_identity
          },
          {
            keyVaultUrl = azurerm_key_vault_secret.redis_connection_string.id
            name        = local.REDISCACHE_CONNECTIONSTRING
            identity    = var.app_identity
          },
          {
            keyVaultUrl = azurerm_key_vault_secret.storage_connection_string.id
            name        = local.AzureWebJobsStorage
            identity    = var.app_identity
          },
          {
            keyVaultUrl = azurerm_key_vault_secret.app_insights_connection_string.id
            name        = local.APPINSIGHTS_INSTRUMENTATIONKEY
            identity    = var.app_identity
          }
        ]
      },
      template = {
        containers = [{
          name = "api",
          env = [
            {
              name  = "REGION"
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
