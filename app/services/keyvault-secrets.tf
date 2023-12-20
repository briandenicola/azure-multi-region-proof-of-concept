resource azurerm_key_vault_secret eventhub_connection_string {
  depends_on = [ 
    azurerm_role_assignment.administrator
  ]
  name         = local.EVENTHUB_CONNECTIONSTRING
  value        = data.azurerm_eventhub_namespace.cqrs_region.default_primary_connection_string
  key_vault_id = data.azurerm_key_vault.cqrs_region.id
}

resource azurerm_key_vault_secret cosmosdb_connection_string {
  depends_on = [ 
    azurerm_role_assignment.administrator
  ]
  name         = local.COSMOSDB_CONNECTIONSTRING
  value        = data.azurerm_cosmosdb_account.cqrs_global.primary_sql_connection_string
  key_vault_id = data.azurerm_key_vault.cqrs_region.id
}

resource azurerm_key_vault_secret redis_connection_string {
  depends_on = [ 
    azurerm_role_assignment.administrator
  ]
  name         = local.REDISCACHE_CONNECTIONSTRING
  value        = data.azurerm_redis_cache.cqrs_region.primary_connection_string
  key_vault_id = data.azurerm_key_vault.cqrs_region.id
}

resource azurerm_key_vault_secret storage_connection_string {
  depends_on = [ 
    azurerm_role_assignment.administrator
  ]
  name         = local.AzureWebJobsStorage
  value        = data.azurerm_storage_account.cqrs_region.primary_connection_string
  key_vault_id = data.azurerm_key_vault.cqrs_region.id
}

resource azurerm_key_vault_secret app_insights_connection_string {
  depends_on = [ 
    azurerm_role_assignment.administrator
  ]
  name         = local.APPINSIGHTS_INSTRUMENTATIONKEY
  value        = data.azurerm_application_insights.cqrs_region.instrumentation_key
  key_vault_id = data.azurerm_key_vault.cqrs_region.id
}