resource "azurerm_private_endpoint" "cosmosdb" {
  name                = "${local.db_name}-ep"
  resource_group_name = azurerm_resource_group.regional_network.name
  location            = azurerm_resource_group.regional_network.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.db_name}-ep"
    private_connection_resource_id = var.cosmosdb_account_id
    subresource_names              = ["sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_documents_azure_com.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_documents_azure_com.id]
  }
}
