resource "azurerm_container_app" "changefeedprocessor" {
  name                         = "changefeedprocessor"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.this.name
  revision_mode                = "Single"
  workload_profile_name        = "default"

  # Define access to backend databases
  #secret 

  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.this.id
    ]
  }

  registry {
    server  = local.acr_name
    identity = data.azurerm_user_assigned_identity.this.id
  }

  template { 
    container {
      name   = "changefeedprocessor"
      image  = local.changefeedprocessor_image
      cpu    = 0.5
      memory = "1Gi"
    }
        # env:
        # - name: AzureFunctionsJobHost__functions__0
        #   value: CosmosChangeFeedProcessor
        # envFrom:
        # - secretRef:
        #     name: cqrssecrets
        # resources:
        #   limits:
        #     cpu: "1"
        #     memory: 512Mi
        #   requests:
        #     cpu: "0.5"
        #     memory: 128Mi
  }
}

