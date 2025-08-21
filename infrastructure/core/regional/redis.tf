resource "azapi_resource" "redis" {
  schema_validation_enabled = false
  type                      = "Microsoft.Cache/redisEnterprise@2024-09-01-preview"
  name                      = local.redis_name
  parent_id                 = azurerm_resource_group.regional_infra.id
  identity {
    type = "SystemAssigned"
  }
  location = azurerm_resource_group.regional_infra.location

  body = {
    sku = {
      name = "Balanced_B5"
    }    
    properties = {      
      highAvailability = "Enabled"
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "cache" {
  name                       = "${local.redis_name}-diag"
  target_resource_id         = azapi_resource.redis.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.cqrs.id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_private_endpoint" "cache" {
  name                = "${local.redis_name}-ep"
  resource_group_name = azurerm_resource_group.regional_infra.name
  location            = azurerm_resource_group.regional_infra.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.redis_name}-ep"
    private_connection_resource_id = azapi_resource.redis.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_redisenterprise_cache_azure_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_redisenterprise_cache_azure_net.id]
  }
}
