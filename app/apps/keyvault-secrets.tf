resource azurerm_key_vault_secret cosmosdb_connection_string {
  depends_on = [ 
    azurerm_role_assignment.administrator
  ]
  name         = local.COSMOSDB_CONNECTIONSTRING
  value        = data.azurerm_cosmosdb_account.cqrs.primary_sql_connection_string
  key_vault_id = data.azurerm_key_vault.cqrs.id
}

resource azurerm_key_vault_secret app_insights_connection_string {
  depends_on = [ 
    azurerm_role_assignment.administrator
  ]
  name         = local.APPINSIGHTS_CONNECTION_STRING
  value        = data.azurerm_application_insights.cqrs.connection_string
  key_vault_id = data.azurerm_key_vault.cqrs.id
}