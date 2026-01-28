resource "azurerm_eventhub_namespace" "this" {
  name                     = local.eventhub_namespace_name
  location                 = azurerm_resource_group.regional_infra.location
  resource_group_name      = azurerm_resource_group.regional_infra.name
  sku                      = "Standard"
  maximum_throughput_units = 5
  auto_inflate_enabled     = true
}

resource "azurerm_monitor_diagnostic_setting" "eventhub" {
  name                       = "diag"
  target_resource_id         = azurerm_eventhub_namespace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ArchiveLogs"
  }

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_log {
    category = "AutoScaleLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_eventhub" "this" {
  name              = local.eventhub_name
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = 15
  message_retention = 7
}

resource "azurerm_eventhub_consumer_group" "this" {
  name                = local.azurerm_eventhub_consumer_group_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this.name
  resource_group_name = azurerm_resource_group.regional_infra.name
}

resource "azurerm_private_endpoint" "eventhub" {
  name                = "${local.eventhub_namespace_name}-ep"
  resource_group_name = azurerm_resource_group.regional_network.name
  location            = azurerm_resource_group.regional_network.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.eventhub_namespace_name}-ep"
    private_connection_resource_id = azurerm_eventhub_namespace.this.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_servicebus_windows_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_servicebus_windows_net.id]
  }
}
