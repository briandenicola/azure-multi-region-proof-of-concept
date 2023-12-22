resource "azurerm_container_app" "utils" {
  
  lifecycle {
    ignore_changes = [
      secret,
      template[0].container[0].env
    ]
  }

  name                         = "utils"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.cqrs_regional.name
  revision_mode                = "Single"
  workload_profile_name        = local.workload_profile_nam

  identity {
    type = "UserAssigned"
    identity_ids = [
      var.app_identity
    ]
  }

  registry {
    server   = local.acr_name
    identity = var.app_identity
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