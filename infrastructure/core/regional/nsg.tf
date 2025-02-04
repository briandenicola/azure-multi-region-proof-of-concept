
resource "azurerm_network_security_group" "cqrs" {
  name                = local.nsg_name
  location            = azurerm_resource_group.cqrs_region.location
  resource_group_name = azurerm_resource_group.cqrs_region.name

  security_rule {
    name                       = "api_management"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = local.apim_subnet_cidr
  }
}

resource "azurerm_subnet_network_security_group_association" "databricks_private_subnet" {
  subnet_id                 = azurerm_subnet.databricks_private.id
  network_security_group_id = azurerm_network_security_group.cqrs.id
}

resource "azurerm_subnet_network_security_group_association" "apim_subnet" {
  subnet_id                 = azurerm_subnet.APIM.id
  network_security_group_id = azurerm_network_security_group.cqrs.id
}

resource "azurerm_subnet_network_security_group_association" "databricks_public_subnet" {
  subnet_id                 = azurerm_subnet.databricks_public.id
  network_security_group_id = azurerm_network_security_group.cqrs.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints_subnet" {
  subnet_id                 = azurerm_subnet.private_endpoints.id
  network_security_group_id = azurerm_network_security_group.cqrs.id
}

resource "azurerm_subnet_network_security_group_association" "nodes_subnet" {
  subnet_id                 = azurerm_subnet.nodes.id
  network_security_group_id = azurerm_network_security_group.cqrs.id
}

resource "azurerm_subnet_network_security_group_association" "appgw_subnet" {
  subnet_id                 = azurerm_subnet.AppGateway.id
  network_security_group_id = azurerm_network_security_group.cqrs.id
}
