resource "azurerm_bastion_host" "this" {
  name                = local.bastion_name
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = azurerm_resource_group.cqrs_region.location
  sku                 = "Developer"
  virtual_network_id  = azurerm_virtual_network.cqrs.id
}
