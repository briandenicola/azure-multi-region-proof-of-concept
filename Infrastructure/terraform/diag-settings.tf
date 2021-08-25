resource "azurerm_monitor_diagnostic_setting" "cosmosdb" {
  name                        = "diag"
  target_resource_id          = azurerm_cosmosdb_account.cqrs_db.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.cqrs_logs.id

  log {
    category = "DataPlaneRequests"
    enabled  = true
  }

  log {
    category = "QueryRuntimeStatistics"
    enabled  = true
  }

  log {
    category = "PartitionKeyStatistics"
    enabled  = true
  }

  log {
    category = "PartitionKeyRUConsumption"
    enabled  = true
  }

  log {
    category = "ControlPlaneRequests"
    enabled  = true
  }

  metric {
    category = "Requests"
  }
}

resource "azurerm_monitor_diagnostic_setting" "arc" {
  name                        = "diag"
  target_resource_id          = azurerm_container_registry.cqrs_acr.id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.cqrs_logs.id

  log {
    category = "ContainerRegistryRepositoryEvents"
    enabled  = true
  }

  log {
    category = "ContainerRegistryLoginEvents"
    enabled  = true
  }
  
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "eventhub_namespace" {
  for_each                    = local.locations_set
  name                        = "diag"
  target_resource_id          = azurerm_eventhub_namespace.cqrs_region[each.key].id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.cqrs_logs.id

  log {
    category = "ArchiveLogs"
    enabled  = true
  }

  log {
    category = "OperationalLogs"
    enabled  = true
  }

  log {
    category = "AutoScaleLogs"
    enabled  = true
  }
  
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "redis" {
  for_each                    = local.locations_set
  name                        = "diag"
  target_resource_id          = azurerm_redis_cache.cqrs_region[each.key].id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.cqrs_logs.id
  
  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  for_each                    = local.locations_set
  name                        = "diag"
  target_resource_id          = azurerm_kubernetes_cluster.cqrs_region[each.key].id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.cqrs_logs.id

  log {
    category = "kube-apiserver"
    enabled  = true
  }

  log {
    category = "kube-audit"
    enabled  = true
  }

  log {
    category = "kube-audit-admin"
    enabled  = true
  }

  log {
    category = "kube-controller-manager"
    enabled  = true
  }
  
  log {
    category = "kube-scheduler"
    enabled  = true
  }
  
  log {
    category = "cluster-autoscaler"
    enabled  = true
  }

  log {
    category = "guard"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  for_each                    = local.locations_set
  name                        = "diag"
  target_resource_id          = azurerm_firewall.cqrs_region[each.key].id
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.cqrs_logs.id

  log {
    category = "AzureFirewallApplicationRule"
    enabled  = true
  }

  log {
    category = "AzureFirewallNetworkRule"
    enabled  = true
  }

  log {
    category = "AzureFirewallDnsProxy"
    enabled  = true
  }

  metric {
    category = "AllMetrics"
  }
}