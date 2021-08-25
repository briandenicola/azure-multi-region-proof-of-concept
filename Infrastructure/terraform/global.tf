resource "azurerm_resource_group" "cqrs_global" {
  name     = "${var.application_name}_global_rg"
  location = element(var.locations, 0)
  tags     = {
    Application = "cqrs"
    Version     = var.application_name
    Components  = "global"
    DeployedOn  = timestamp()
  }
}

resource "azurerm_cosmosdb_account" "cqrs_db" {
  name                            = var.cosmosdb_name
  resource_group_name             = azurerm_resource_group.cqrs_global.name
  location                        = azurerm_resource_group.cqrs_global.location
  offer_type                      = "Standard"
  kind                            = "GlobalDocumentDB"
  enable_multiple_write_locations = true
  enable_automatic_failover       = true

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

resource "azurerm_cosmosdb_sql_database" "cqrs_db" {
  depends_on          = [azurerm_cosmosdb_account.cqrs_db]
  name                = var.cosmosdb_database_name
  resource_group_name = azurerm_cosmosdb_account.cqrs_db.resource_group_name
  account_name        = azurerm_cosmosdb_account.cqrs_db.name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_container" "cqrs_db" {
  depends_on          = [azurerm_cosmosdb_sql_database.cqrs_db]
  name                = var.cosmosdb_collections_name
  resource_group_name = azurerm_cosmosdb_account.cqrs_db.resource_group_name
  account_name        = azurerm_cosmosdb_account.cqrs_db.name
  database_name       = azurerm_cosmosdb_sql_database.cqrs_db.name
  partition_key_path  = "/keyId"
  throughput          = 400
}

resource "azurerm_container_registry" "cqrs_acr" {
  name                     = var.acr_account_name
  resource_group_name      = azurerm_resource_group.cqrs_global.name
  location                 = azurerm_resource_group.cqrs_global.location
  sku                      = "Premium"
  admin_enabled            = false
  #georeplication_locations = length(var.locations) - 1 >= 1 ? slice(var.locations, 1, length(var.locations)) : null

  dynamic "georeplications" {
    for_each = length(var.locations) - 1 >= 1 ? slice(var.locations, 1, length(var.locations)) : []
    iterator = each
    content {
      location                = each.value
      #zone_redundancy_enabled = true
    }
  } 

  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action   = "Allow"
      ip_range = var.api_server_authorized_ip_ranges
    }
  }

  provisioner "local-exec" {
    command = "az acr update -n ${var.acr_account_name} --data-endpoint-enabled true"
  }
}

resource "azurerm_log_analytics_workspace" "cqrs_logs" {
  name                = var.loganalytics_account_name
  resource_group_name = azurerm_resource_group.cqrs_global.name
  location            = azurerm_resource_group.cqrs_global.location
  sku                 = "pergb2018"
}

resource "azurerm_application_insights" "cqrs_ai" {
  name                = var.ai_account_name
  resource_group_name = azurerm_resource_group.cqrs_global.name
  location            = azurerm_resource_group.cqrs_global.location
  application_type    = "web"
}
