resource "azurerm_storage_account" "this" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.regional_infra.name
  location                 = azurerm_resource_group.regional_infra.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_private_endpoint" "blob_endpoint" {
  name                = "${local.storage_name}-blob-ep"
  resource_group_name = azurerm_resource_group.regional_network.name
  location            = azurerm_resource_group.regional_network.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.storage_name}-blob-ep"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_blob_core_windows_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_blob_core_windows_net.id]
  }
}

resource "azurerm_private_endpoint" "file_endpoint" {
  name                = "${local.storage_name}-file-ep"
  resource_group_name = azurerm_resource_group.regional_network.name
  location            = azurerm_resource_group.regional_network.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.storage_name}-file-ep"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_file_core_windows_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_file_core_windows_net.id]
  }
}

resource "azurerm_private_endpoint" "table_endpoint" {
  name                = "${local.storage_name}-table-ep"
  resource_group_name = azurerm_resource_group.regional_network.name
  location            = azurerm_resource_group.regional_network.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.storage_name}-table-ep"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_table_core_windows_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_table_core_windows_net.id]
  }
}

resource "azurerm_private_endpoint" "queue_endpoint" {
  name                = "${local.storage_name}-queue-ep"
  resource_group_name = azurerm_resource_group.regional_network.name
  location            = azurerm_resource_group.regional_network.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.storage_name}-queue-ep"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_queue_core_windows_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_queue_core_windows_net.id]
  }
}
