output "ACR_NAME" {
  value = azurerm_container_registry.this.name
}

output "COSMOSDB_NAME" {
  value = azurerm_cosmosdb_account.this.name
}

output "AZURE_STATIC_WEBAPP_NAME" {
  value = var.deploying_externally ? azurerm_static_web_app.ui[0].name : ""
}

output "APP_INSIGHTS_CONNECTION_STRING" {
  value     = azurerm_application_insights.this.connection_string
  sensitive = false
}

output "LOG_ANALYTICS_WORKSPACE_ID" {
  value = azurerm_log_analytics_workspace.this.id
}

output "COSMOSDB_ACCOUNT_ID" {
  value = azurerm_cosmosdb_account.this.id
}