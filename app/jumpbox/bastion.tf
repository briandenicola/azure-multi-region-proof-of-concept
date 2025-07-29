resource "azurerm_bastion_host" "this" {
  depends_on = [ 
    azurerm_resource_group.cqrs_vm
  ]

  name                = "${var.vm.app_name}-bastion"
  resource_group_name = var.vm.resource_group_name
  location            = var.vm.location
  sku                 = "Developer"
  virtual_network_id  = data.azurerm_virtual_network.this.id
}
