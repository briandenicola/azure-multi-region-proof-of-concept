output "ACR_NAME" {
  value = azurerm_container_registry.cqrs_acr.name
}

output "COSMOSDB_NAME" {
  value = azurerm_cosmosdb_account.cqrs_db.name
}

output "AZURE_STATIC_WEBAPP_NAME" {
  value = azurerm_static_web_app.ui[0].name
}