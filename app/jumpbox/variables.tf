variable "vm" {
  type = object({
    name                = string
    location            = string
    resource_group_name = string
    sku                 = string
    admin = object({
      username = string
      ssh_key_path        = string
    })
    vnet = object({
      name = string
      rg_name  = string
    })
  })
}
