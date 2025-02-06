data "azurerm_container_registry" "cqrs" {
  name                = local.acr_name
  resource_group_name = local.global_rg_name
}

resource "azurerm_private_endpoint" "acr" {
  name                = "${local.acr_name}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = azurerm_resource_group.cqrs_region.location
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${local.acr_name}-ep"
    private_connection_resource_id = data.azurerm_container_registry.cqrs.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_azurecr_io.name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_azurecr_io.id]
  }
}
