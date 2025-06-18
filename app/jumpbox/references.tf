data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "azurerm_subnet" "compute" {
  name                 = "compute"
  resource_group_name  = var.vm.vnet.rg_name
  virtual_network_name = var.vm.vnet.name
}

data "azurerm_virtual_network" "this" {
  name = var.vm.vnet.name
  resource_group_name  = var.vm.vnet.rg_name
}
