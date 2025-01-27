resource "azapi_resource" "cache" {
  schema_validation_enabled = false
  type                      = "Microsoft.Cache/redisEnterprise@2024-09-01-preview"
  name                      = local.cache_name
  parent_id                 = azurerm_resource_group.this.id
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids =  [
      azurerm_user_assigned_identity.this.id
    ]
  }
  location = azurerm_resource_group.this.location

  body = {
    sku = {
      name = local.cache_sku
    }    
    properties = {
      encryption = {
        customerManagedKeyEncryption = {
          keyEncryptionKeyIdentity = {
            identityType = "userAssignedIdentity"
            userAssignedIdentityResourceId = azurerm_user_assigned_identity.this.id
          }
          keyEncryptionKeyUrl = azurerm_key_vault_key.this.id
        }
      }      
      highAvailability = "Enabled"
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "${local.cache_name}-diag"
  target_resource_id         = azapi_resource.cache.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_private_endpoint" "redis" {
  name                = "${local.cache_name}-endpoint"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  subnet_id           = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "${local.cache_name}-endpoint"
    private_connection_resource_id = azapi_resource.cache.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_redisenterprise_cache_azure_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_redisenterprise_cache_azure_net.id]
  }
}

resource "azapi_resource" "database" {
  schema_validation_enabled = false
  type                      = "Microsoft.Cache/redisEnterprise/databases@2024-09-01-preview"
  name                      = local.redis_database_name
  parent_id                 = azapi_resource.cache.id
  body = {
    properties = {
      accessKeysAuthentication = "Disabled"
      clientProtocol           = "Encrypted"
      clusteringPolicy         = "EnterpriseCluster"
      deferUpgrade             = "NotDeferred"
      evictionPolicy           = "VolatileLRU"
      modules = [
        {
          name = "RedisTimeSeries"
        }
      ]
    }
  }
}
