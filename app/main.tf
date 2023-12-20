data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "http" "myip" {
  url = "http://checkip.amazonaws.com/"
}

locals {
  global_rg_name    = "${var.app_name}_global_rg"
  acr_name          = "${replace(var.app_name, "-", "")}acr"
  workload_identity = "${var.app_name}-app-identity"
}

module "container_apps" {
  depends_on = [
    azurerm_role_assignment.acr_pullrole_node,
  ]

  for_each                  = toset(var.locations)
  source                    = "./services"
  location                  = each.value
  app_name                  = var.app_name
  commit_version            = var.commit_version
  custom_domain             = var.custom_domain
  app_identity              = azurerm_user_assigned_identity.app_identity.id
  app_identity_principal_id = azurerm_user_assigned_identity.app_identity.principal_id
}

data "azurerm_container_registry" "cqrs_acr" {
  name                = local.acr_name
  resource_group_name = local.global_rg_name
}

data "azurerm_resource_group" "cqrs_global" {
  name = local.global_rg_name
}
