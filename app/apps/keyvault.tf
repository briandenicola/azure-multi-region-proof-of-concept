
resource "azurerm_key_vault" "this" {
  name                       = local.kv_name
  resource_group_name        = azurerm_resource_group.regional_apps.name
  location                   = azurerm_resource_group.regional_apps.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = true

  sku_name = "standard"

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = [var.authorized_ip_ranges]
  }
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "${local.kv_name}-ep"
  resource_group_name = local.vnet_rg_name
  location            = azurerm_resource_group.regional_apps.location
  subnet_id           = data.azurerm_subnet.pe.id

  private_service_connection {
    name                           = "${local.kv_name}-ep"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "privatelink.vaultcore.azure.net"
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.privatelink_vaultcore_azure_net.id
    ]
  }
}
