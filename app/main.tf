locals {
  global_rg_name    = "${var.app_name}_global_rg"
}

module "jumpbox" {
  for_each              = toset(var.locations)
  source                = "./jumpbox"
  vm = {
    name                = "${var.app_name}-${each.value}-jumpbox"
    resource_group_name = "${var.app_name}_${each.value}_apps_rg"
    location            = each.value
    sku                 = "Standard_B1s"
    admin = {
      username     = "manager"
      ssh_key_path = "~/.ssh/id_rsa.pub"
    }
    vnet = {
      name    = "${var.app_name}-${each.value}-vnet"
      rg_name = "${var.app_name}_${each.value}_infra_rg" 
    }
  }
}