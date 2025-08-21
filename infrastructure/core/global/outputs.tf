output "ACR_NAME" {
  value = azurerm_container_registry.this.name
}

output "COSMOSDB_NAME" {
  value = azurerm_cosmosdb_account.this.name
}

output "AZURE_STATIC_WEBAPP_NAME" {
  value = var.deploying_externally ? azurerm_static_web_app.ui[0].name : "" 
}