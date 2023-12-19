resource "azurerm_storage_account" "cqrs_region" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.cqrs_region.name
  location                 = azurerm_resource_group.cqrs_region.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_private_endpoint" "storage_account" {
  name                = "${local.storage_name}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = azurerm_resource_group.cqrs_region.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.storage_name}-ep"
    private_connection_resource_id = azurerm_storage_account.cqrs_region.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_blob_core_windows_net.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_blob_core_windows_net.id]
  }
}
