data "http" "myip" {
  url = "http://checkip.amazonaws.com/"
}

resource "random_id" "this" {
  byte_length = 2
}

resource "random_pet" "this" {
  length    = 1
  separator = ""
}

locals {
  resource_name = "${random_pet.this.id}-${random_id.this.dec}"
}

module "global_resources" {
  source                          = "./global"
  api_server_authorized_ip_ranges = "${chomp(data.http.myip.response_body)}/32"
  locations                       = var.locations
  app_name                        = local.resource_name
}

module "regional_resources" {
  for_each                        = toset(var.locations)
  source                          = "./regional"
  location                        = each.value
  primary_location                = element(var.locations, 0)
  app_name                        = local.resource_name
  custom_domain                   = var.custom_domain
}