data azurerm_cosmosdb_account cqrs_db {
  name                     = local.db_name
  resource_group_name      = local.global_rg_name
}

resource "azurerm_private_endpoint" "cosmos_db" {
  name                = "${local.db_name}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = azurerm_resource_group.cqrs_region.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.db_name}-ep"
    private_connection_resource_id = data.azurerm_cosmosdb_account.cqrs_db.id
    subresource_names              = ["sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_documents_azure_com.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_documents_azure_com.id]
  }
}