data "azurerm_container_app_environment" "this" {
  name                = local.aca_name
  resource_group_name = local.infra_rg_name
}

data "azurerm_container_app_environment_certificate" "this" {
  name                         = replace(var.custom_domain, ".", "-")
  container_app_environment_id = data.azurerm_container_app_environment.this.id
}