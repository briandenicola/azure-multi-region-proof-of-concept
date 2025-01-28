resource "azurerm_container_app_environment" "env" {
  depends_on = [
    azurerm_subnet.nodes
  ]
  name                                        = local.aca_name
  resource_group_name                         = azurerm_resource_group.cqrs_region.name
  location                                    = azurerm_resource_group.cqrs_region.location
  infrastructure_resource_group_name          = "${local.aca_name}_nodes_rg"
  infrastructure_subnet_id                    = azurerm_subnet.nodes.id
  internal_load_balancer_enabled              = true
  zone_redundancy_enabled                     = false
  log_analytics_workspace_id                  = data.azurerm_log_analytics_workspace.cqrs.id
  dapr_application_insights_connection_string = data.azurerm_application_insights.cqrs.connection_string
  mutual_tls_enabled                          = true

  workload_profile {
    name                  = local.workload_profile_name
    workload_profile_type = local.workload_profile_size
    minimum_count         = 3
    maximum_count         = 5
  }
}

resource "azurerm_container_app_environment_certificate" "custom" {
  name                         = replace(var.custom_domain, ".", "-")
  container_app_environment_id = azurerm_container_app_environment.env.id
  certificate_blob_base64      = filebase64(var.certificate_file_path)
  certificate_password         = var.certificate_password
}
