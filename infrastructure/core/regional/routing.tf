resource azurerm_route_table cqrs_region {
  name                          = local.route_table_name
  resource_group_name           = azurerm_resource_group.cqrs_region.name
  location                      = azurerm_resource_group.cqrs_region.location

  route {
    name                   = "DefaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.cqrs_region.ip_configuration[0].private_ip_address
  }

  route {
    name           = "FirewallIP"
    address_prefix = "${azurerm_public_ip.firewall.ip_address}/32"
    next_hop_type  = "Internet"
  }
}

resource azurerm_subnet_route_table_association cqrs_region {
  subnet_id      = azurerm_subnet.nodes.id
  route_table_id = azurerm_route_table.cqrs_region.id
}
