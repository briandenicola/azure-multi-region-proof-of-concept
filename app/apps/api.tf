resource "azurerm_container_app" "api" {
  lifecycle {
    ignore_changes = [
      secret,
      template[0].container[0].env,
    ]
  }

  name                         = "api-internal"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.cqrs_apps.name
  revision_mode                = "Multiple"
  workload_profile_name        = local.workload_profile_name

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.app_identity.id
    ]
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true #Allow traffic from outside the Container Apps Environment. Does not mean external traffic from the Internet. 
    target_port                = 8080
    transport                  = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  registry {
    server   = local.acr_name
    identity = azurerm_user_assigned_identity.app_identity.id
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

      env {
        name  = "REGION"
        value = var.location
      }
      env {
        name        = "APPINSIGHTS_INSTRUMENTATIONKEY"
        secret_name = local.APPINSIGHTS_INSTRUMENTATIONKEY
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
        name        = "EVENTHUB_CONNECTIONSTRING"
        secret_name = local.EVENTHUB_CONNECTIONSTRING
      }
      env {
        name        = "AzureWebJobsStorage"
        secret_name = local.AzureWebJobsStorage
      }
    }

    max_replicas = 5
    min_replicas = 1

    http_scale_rule {
      name                = "http"
      concurrent_requests = 100
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
  }
}

resource "azurerm_container_app_custom_domain" "api" {
  depends_on = [
    azurerm_container_app.api
  ]
  name                                     = "api-internal.${var.custom_domain}"
  certificate_binding_type                 = "SniEnabled"
  container_app_id                         = azurerm_container_app.api.id
  container_app_environment_certificate_id = data.azurerm_container_app_environment_certificate.this.id
}
