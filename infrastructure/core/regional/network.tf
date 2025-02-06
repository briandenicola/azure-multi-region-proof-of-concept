
resource "azurerm_virtual_network" "cqrs" {
  name                = local.vnet_name
  location            = azurerm_resource_group.cqrs_region.location
  resource_group_name = azurerm_resource_group.cqrs_region.name
  address_space       = [local.vnet_cidr]
}

resource "azurerm_subnet" "AzureFirewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.cqrs_region.name
  virtual_network_name = azurerm_virtual_network.cqrs.name
  address_prefixes     = [local.fw_subnet_cidr]
}

resource "azurerm_subnet" "AppGateway" {
  name                 = "AppGateway"
  resource_group_name  = azurerm_resource_group.cqrs_region.name
  virtual_network_name = azurerm_virtual_network.cqrs.name
  address_prefixes     = [local.appgw_subnet_cidr]
}

resource "azurerm_subnet" "APIM" {
  name                 = "APIM"
  resource_group_name  = azurerm_resource_group.cqrs_region.name
  virtual_network_name = azurerm_virtual_network.cqrs.name
  address_prefixes     = [local.apim_subnet_cidr]
}

resource "azurerm_subnet" "compute" {
  name                 = "compute"
  resource_group_name  = azurerm_resource_group.cqrs_region.name
  virtual_network_name = azurerm_virtual_network.cqrs.name
  address_prefixes     = [local.compute_subnet_cidr]
}

resource "azurerm_subnet" "databricks_private" {
  name                 = "databricks-private"
  resource_group_name  = azurerm_resource_group.cqrs_region.name
  virtual_network_name = azurerm_virtual_network.cqrs.name
  address_prefixes     = [local.databricks_private_subnet_cidr]
}

resource "azurerm_subnet" "databricks_public" {
  name                 = "databricks-public"
  resource_group_name  = azurerm_resource_group.cqrs_region.name
  virtual_network_name = azurerm_virtual_network.cqrs.name
  address_prefixes     = [local.databricks_public_subnet_cidr]
}

resource "azurerm_subnet" "private_endpoints" {
  name                 = "private_endpoints"
  resource_group_name  = azurerm_resource_group.cqrs_region.name
  virtual_network_name = azurerm_virtual_network.cqrs.name
  address_prefixes     = [local.pe_subnet_cidr]
}

resource "azurerm_subnet" "nodes" {
  name                 = "nodes"
  resource_group_name  = azurerm_resource_group.cqrs_region.name
  virtual_network_name = azurerm_virtual_network.cqrs.name
  address_prefixes     = [local.nodes_subnet_cidr]

  delegation {
    name = "aca-delegation"

    service_delegation {
      name = "Microsoft.App/environments"
    }
  }
}
