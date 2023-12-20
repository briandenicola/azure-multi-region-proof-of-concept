resource "azurerm_container_app" "eventprocessor" {
  name                         = "eventprocessor"
  container_app_environment_id = data.azurerm_container_app_environment.this.id
  resource_group_name          = data.azurerm_resource_group.cqrs_regional.name
  revision_mode                = "Single"
  workload_profile_name        = "default"

  # Define access to backend databases
  #secret 


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

    # Environment variables
    # AzureWebJobsStorage: {{.Values.AzureWebJobsStorage}}       
    # FUNCTIONS_WORKER_RUNTIME: ZG90bmV0                
    # EVENTHUB_CONNECTIONSTRING: {{.Values.EVENTHUB_CONNECTIONSTRING}}  
    # COSMOSDB_CONNECTIONSTRING: {{.Values.COSMOSDB_CONNECTIONSTRING}}   
    # REDISCACHE_CONNECTIONSTRING: {{.Values.REDISCACHE_CONNECTIONSTRING}}
    # APPINSIGHTS_INSTRUMENTATIONKEY: {{.Values.APPINSIGHTS_INSTRUMENTATIONKEY}}
    # LEASE_COLLECTION_PREFIX: {{.Values.LEASE_COLLECTION_PREFIX}}

    #  env:
    #   - name: AzureFunctionsJobHost__functions__0
    #     value: CommandProcessing
    #   envFrom:
    #   - secretRef:
    #       name: cqrssecrets
    #   resources:
    #     limits:
    #       cpu: "1"
    #       memory: 512Mi
    #     requests:
    #       cpu: "0.5"
    #       memory: 128Mi

    # Need to define Keda scaling rules here
    # kind: ScaledObject
    # metadata:
    #   name: eventprocessor
    # spec:
    #   scaleTargetRef:
    #     name: eventprocessor
    #   minReplicaCount: 0
    #   maxReplicaCount: 15
    #   cooldownPeriod:  120
    #   pollingInterval: 15
    #   triggers:
    #   - type: azure-eventhub
    #     metadata:
    #       consumerGroup: eventsfunction
    #       checkpointStrategy: azureFunction
    #       connectionFromEnv: EVENTHUB_CONNECTIONSTRING
    #       storageConnectionFromEnv: AzureWebJobsStorage

    container {
      name   = "eventprocessor"
      image  = local.eventprocessor_image
      cpu    = 0.5
      memory = "1Gi"


    }
  }
}

