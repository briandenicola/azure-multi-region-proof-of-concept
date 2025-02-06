data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}


data "azurerm_subnet" "compute" {
  name                 = "APIM" #"compute"
  resource_group_name  = var.vm.vnet.rg_name
  virtual_network_name = var.vm.vnet.name
}
