resource "azurerm_container_app" "api" {
  name                         = "api"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = local.apps_rg_name
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
    server   = local.acr_fqdn
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
        name        = "APPINSIGHTS_CONNECTION_STRING"
        secret_name = local.APPINSIGHTS_CONNECTION_STRING
      }
      env {
        name        = "COSMOSDB_CONNECTIONSTRING"
        secret_name = local.COSMOSDB_CONNECTIONSTRING
      }

      env {
        name  = "APPLICATION_CLIENT_ID"
        value = azurerm_user_assigned_identity.app_identity.client_id
      }

      env {
        name  = "REDISCACHE_CONNECTIONSTRING"
        value = "${local.redis_name}.${var.location}.redis.azure.net:10000"
      }

      env {
        name  = "EVENTHUB_CONNECTIONSTRING"
        value = "${local.eventhub_namespace_name}.servicebus.windows.net" 
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

resource "azurerm_container_app_custom_domain" "api" {
  depends_on = [
    azurerm_container_app.api
  ]
  name                                     = "api.ingress.${var.custom_domain}"
  certificate_binding_type                 = "SniEnabled"
  container_app_id                         = azurerm_container_app.api.id
  container_app_environment_certificate_id = data.azurerm_container_app_environment_certificate.this.id
}
