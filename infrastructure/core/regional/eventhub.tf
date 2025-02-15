resource "azurerm_eventhub_namespace" "cqrs" {
  name                     = local.eventhub_namespace_name
  location                 = azurerm_resource_group.cqrs_apps.location
  resource_group_name      = azurerm_resource_group.cqrs_apps.name
  sku                      = "Standard"
  maximum_throughput_units = 5
  auto_inflate_enabled     = true
}

resource "azurerm_monitor_diagnostic_setting" "eventhub" {
  name                       = "diag"
  target_resource_id         = azurerm_eventhub_namespace.cqrs.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.cqrs.id

  enabled_log {
    category = "ArchiveLogs"
  }

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_log {
    category = "AutoScaleLogs"
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_eventhub" "cqrs" {
  name              = local.eventhub_name
  namespace_id      = azurerm_eventhub_namespace.cqrs.id
  partition_count   = 15
  message_retention = 7
}

resource "azurerm_eventhub_consumer_group" "cqrs" {
  name                = local.azurerm_eventhub_consumer_group_name
  namespace_name      = azurerm_eventhub_namespace.cqrs.name
  eventhub_name       = azurerm_eventhub.cqrs.name
  resource_group_name = azurerm_resource_group.cqrs_apps.name
}

resource "azurerm_private_endpoint" "eventhub" {
  name                = "${local.eventhub_namespace_name}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = azurerm_resource_group.cqrs_region.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.eventhub_namespace_name}-ep"
    private_connection_resource_id = azurerm_eventhub_namespace.cqrs.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_servicebus_windows_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_servicebus_windows_net.id]
  }
}
