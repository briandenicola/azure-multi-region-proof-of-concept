resource "azurerm_container_registry" "cqrs" {
  name                     = local.acr_name
  resource_group_name      = azurerm_resource_group.cqrs_global.name
  location                 = azurerm_resource_group.cqrs_global.location
  sku                      = "Premium"
  admin_enabled            = false
  data_endpoint_enabled    = true 

  dynamic "georeplications" {
    for_each = length(var.locations) - 1 >= 1 ? slice(var.locations, 1, length(var.locations)) : []
    iterator = each
    content {
      location                = each.value
    }
  } 

  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action   = "Allow"
      ip_range = var.authorized_ip_ranges
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "acr" {
  name                        = "diag"
  target_resource_id          = azurerm_container_registry.cqrs.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.cqrs.id

  enabled_log {
    category = "ContainerRegistryRepositoryEvents"
  }

  enabled_log {
    category = "ContainerRegistryLoginEvents"
  }
  
  metric {
    category = "AllMetrics"
  }
}