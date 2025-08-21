resource "azurerm_cosmosdb_account" "this" {
  name                             = local.db_name
  resource_group_name              = azurerm_resource_group.global.name
  location                         = azurerm_resource_group.global.location
  offer_type                       = "Standard"
  kind                             = "GlobalDocumentDB"
  automatic_failover_enabled       = true
  multiple_write_locations_enabled = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = element(var.locations, 0)
    failover_priority = 0
  }

  dynamic "geo_location" {
    for_each = slice(var.locations, 1, length(var.locations))
    content {
      location          = geo_location.value
      failover_priority = 1
    }
  }
}

resource "azurerm_cosmosdb_sql_database" "keys" {
  depends_on          = [azurerm_cosmosdb_account.this]
  name                = local.cosmosdb_database_name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_container" "items" {
  depends_on          = [azurerm_cosmosdb_sql_database.keys]
  name                = local.cosmosdb_collections_name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.keys.name
  partition_key_paths = ["/keyId"]
  throughput          = 400
}

resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  name                       = "diag"
  target_resource_id         = azurerm_cosmosdb_account.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "DataPlaneRequests"
  }

  enabled_log {
    category = "QueryRuntimeStatistics"
  }

  enabled_log {
    category = "PartitionKeyStatistics"
  }

  enabled_log {
    category = "PartitionKeyRUConsumption"
  }

  enabled_log {
    category = "ControlPlaneRequests"
  }
}
