data "http" "myip" {
  url = "http://checkip.amazonaws.com/"
}

locals {
  regional_name             = "${var.app_name}-${var.location}"
  rg_name                   = "${local.regional_name}_rg"
  global_rg_name            = "${var.app_name}_global_rg"
  acr_name                  = "${replace(var.app_name, "-", "")}acr.azurecr.io"
  aca_name                  = "${local.regional_name}-env"
  workload_identity         = "${local.regional_name}-app-identity"
  api_image                 = "${local.acr_name}/cqrs/api:${var.commit_version}"
  eventprocessor_image      = "${local.acr_name}/cqrs/eventprocessor:${var.commit_version}"
  changefeedprocessor_image = "${local.acr_name}/cqrs/changefeedprocessor:${var.commit_version}"
}

data "azurerm_resource_group" "this" {
  name = local.rg_name
}

data "azurerm_container_app_environment" "this" {
  name                = local.aca_name
  resource_group_name = data.azurerm_resource_group.this.name
}

data "azurerm_container_app_environment_certificate" "this" {
  name                         = replace(var.custom_domain, ".", "-")
  container_app_environment_id = data.azurerm_container_app_environment.this.id
}

data "azurerm_user_assigned_identity" "this" {
  name                = local.workload_identity
  resource_group_name = data.azurerm_resource_group.this.name
}
