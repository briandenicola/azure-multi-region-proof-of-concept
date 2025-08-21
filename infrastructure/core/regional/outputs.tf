output "APP_INGRESS_IP" {
  value = azurerm_container_app_environment.env.static_ip_address
}

output "AZURE_CONTAINER_APP_STATIC_IP" {
  value = azurerm_container_app_environment.env.static_ip_address
}

output "AZURE_REDIS_CLUSTER_DATABASE_ID" {
  value = azapi_resource.redis.id
}
