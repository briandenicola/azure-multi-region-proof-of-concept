resource "azurerm_container_app_environment" "env" {
  name                           = local.aca_name
  location                       = azurerm_resource_group.cqrs_region.location
  resource_group_name            = azurerm_resource_group.cqrs_region.name
  log_analytics_workspace_id     = data.azurerm_log_analytics_workspace.cqrs_logs.workspace_id
  infrastructure_subnet_id       = azurerm_subnet.nodes.id
  internal_load_balancer_enabled = true
  zone_redundancy_enabled        = true

  workload_profile {
    name                  = local.workload_profile_name
    minimum_count         = 3
    maximum_count         = 5
    workload_profile_type = local.workload_profile_size
  }
}

resource "azurerm_container_app_environment_certificate" "custom" {
  name                         = replace(var.custom_domain, ".", "-")
  container_app_environment_id = azurerm_container_app_environment.env.id
  certificate_blob_base64      = filebase64(var.certificate_file_path)
  certificate_password         = var.certificate_password
}
