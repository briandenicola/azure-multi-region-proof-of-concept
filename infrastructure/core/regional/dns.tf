
resource "azurerm_private_dns_zone" "privatelink_azurecr_io" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_azurecr_io" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_azurecr_io.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_zone" "privatelink_documents_azure_com" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_documents_azure_com" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_documents_azure_com.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_zone" "privatelink_blob_core_windows_net" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_blob_core_windows_net" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_blob_core_windows_net.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_zone" "privatelink_queue_core_windows_net" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_queue_core_windows_net" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_queue_core_windows_net.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_zone" "privatelink_file_core_windows_net" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_file_core_windows_net" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_file_core_windows_net.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_zone" "privatelink_table_core_windows_net" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_table_core_windows_net" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_table_core_windows_net.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_zone" "privatelink_servicebus_windows_net" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_servicebus_windows_net" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_servicebus_windows_net.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_zone" "privatelink_redisenterprise_cache_azure_net" {
  name                = "privatelink.redisenterprise.cache.azure.net"
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_redisenterprise_cache_azure_net" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_redisenterprise_cache_azure_net.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_zone" "privatelink_vaultcore_azure_net" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_vaultcore_azure_net" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_vaultcore_azure_net.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_zone" "custom_domain" {
  name                = var.custom_domain
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "custom_domain" {
  name                  = "${azurerm_virtual_network.cqrs.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.custom_domain.name
  resource_group_name   = azurerm_resource_group.cqrs_region.name
  virtual_network_id    = azurerm_virtual_network.cqrs.id
}

resource "azurerm_private_dns_a_record" "containerapps" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.custom_domain.name
  resource_group_name = azurerm_resource_group.cqrs_region.name
  ttl                 = 300
  records = [
    azurerm_container_app_environment.env.static_ip_address
  ]
}
