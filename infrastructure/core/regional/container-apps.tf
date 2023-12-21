#
# azurerm supports workload profiles but does not support the ability to set the infrastructure resource group
# resource "azurerm_container_app_environment" "env" {
#   name                                        = local.aca_name
#   location                                    = azurerm_resource_group.cqrs_region.location
#   resource_group_name                         = azurerm_resource_group.cqrs_region.name
#   log_analytics_workspace_id                  = data.azurerm_log_analytics_workspace.cqrs_logs.id
#   dapr_application_insights_connection_string = data.azurerm_application_insights.cqrs_app_insights.connection_string
#   infrastructure_subnet_id                    = azurerm_subnet.nodes.id
#   internal_load_balancer_enabled              = true
#   zone_redundancy_enabled                     = true

#   workload_profile {
#     name                  = local.workload_profile_name
#     minimum_count         = 3
#     maximum_count         = 5
#     workload_profile_type = local.workload_profile_size
#   }
#}
#

resource "azapi_resource" "azurerm_container_app_environment" {

  type      = "Microsoft.App/managedEnvironments@2023-05-01"
  name      = local.aca_name
  location  = azurerm_resource_group.cqrs_region.location
  parent_id = azurerm_resource_group.cqrs_region.id

  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = data.azurerm_log_analytics_workspace.cqrs_logs.workspace_id
          sharedKey  = data.azurerm_log_analytics_workspace.cqrs_logs.primary_shared_key
        }
      }
      daprAIInstrumentationKey    = data.azurerm_application_insights.cqrs_app_insights.instrumentation_key
      daprAIConnectionString      = data.azurerm_application_insights.cqrs_app_insights.connection_string
      infrastructureResourceGroup = "${local.aca_name}_nodes_rg"
      zoneRedundant               = true

      peerAuthentication = {
        mtls = {
          enabled = true 
        }
      }

      vnetConfiguration = {
        infrastructureSubnetId = azurerm_subnet.nodes.id
        internal               = true
      }

      workloadProfiles = [{
        minimumCount        = 3
        maximumCount        = 5
        name                = local.workload_profile_name
        workloadProfileType = local.workload_profile_size
      }]
    }
  })
}

data "azurerm_container_app_environment" "env" {
  depends_on = [
    azapi_resource.azurerm_container_app_environment
  ]
  name                = local.aca_name
  resource_group_name = azurerm_resource_group.cqrs_region.name
}

resource "azurerm_container_app_environment_certificate" "custom" {
  name                         = replace(var.custom_domain, ".", "-")
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  certificate_blob_base64      = filebase64(var.certificate_file_path)
  certificate_password         = var.certificate_password
}
