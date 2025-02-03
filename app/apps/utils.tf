resource "azurerm_container_app" "utils" {

  lifecycle {
    ignore_changes = [
      secret,
      template[0].container[0].env
    ]
  }
  count                        = var.deploy_utils ? 1 : 0
  name                         = "utils"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = local.apps_rg_name
  revision_mode                = "Single"
  workload_profile_name        = local.workload_profile_name

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.app_identity.id
    ]
  }

  registry {
    server   = local.acr_name
    identity = azurerm_user_assigned_identity.app_identity.id
  }

  template {
    container {
      name   = "utils"
      image  = local.utils_image
      cpu    = 1
      memory = "2Gi"
    }
  }
}
