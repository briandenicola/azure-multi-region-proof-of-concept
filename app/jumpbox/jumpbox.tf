
resource "azurerm_resource_group" "cqrs_vm" {
  name     = var.vm.resource_group_name
  location = var.vm.location
  tags = {
    Application = var.vm.tags
    AppName     = var.vm.app_name
    Components  = "Jumpbox Virtual Machine, User Assigned Identity, Network Interface"
    DeployedOn  = timestamp()
  }
}

resource "azurerm_user_assigned_identity" "this" {
  depends_on = [ 
    azurerm_resource_group.cqrs_vm
  ]

  name                = "${var.vm.name}-identity"
  resource_group_name = var.vm.resource_group_name
  location            = var.vm.location
}

resource "azurerm_network_interface" "this" {
  depends_on = [ 
    azurerm_resource_group.cqrs_vm
  ]

  name                = "${var.vm.name}-nic"
  resource_group_name = var.vm.resource_group_name
  location            = var.vm.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.compute.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  depends_on = [ 
    azurerm_resource_group.cqrs_vm
  ]

  name                = "${var.vm.name}-linux"
  resource_group_name = var.vm.resource_group_name
  location            = var.vm.location
  size                = var.vm.sku
  admin_username      = var.vm.admin.username
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = var.vm.admin.username
    public_key = file(var.vm.admin.ssh_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${var.vm.name}-osdisk" 
  }

  identity {
    type = "UserAssigned"
    identity_ids = [ 
        azurerm_user_assigned_identity.this.id
    ]
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
