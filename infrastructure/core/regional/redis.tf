resource "azurerm_redis_enterprise_cluster" "cqrs" {
  name                = local.redis_name
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = var.location
  zones               = [1, 2, 3]
  sku_name            = "Enterprise_E20-4" #Will migrate to Balanced_B250 once available in azurerm
}

resource "azurerm_monitor_diagnostic_setting" "cache" {
  name                       = "${local.redis_name}-diag"
  target_resource_id         = azurerm_redis_enterprise_cluster.cqrs.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.cqrs.id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_private_endpoint" "cache" {
  name                = "${local.redis_name}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = azurerm_resource_group.cqrs_region.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.redis_name}-ep"
    private_connection_resource_id = azurerm_redis_enterprise_cluster.cqrs.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_redisenterprise_cache_azure_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_redisenterprise_cache_azure_net.id]
  }
}