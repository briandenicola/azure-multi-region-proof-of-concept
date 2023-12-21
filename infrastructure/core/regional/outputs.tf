output "APP_INGRESS_IP" {
  value = azurerm_container_app_environment.env.static_ip_address
}
