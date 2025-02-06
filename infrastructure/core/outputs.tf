output APP_NAME {
  value     = local.resource_name
  sensitive = false
}

output "ACR_NAME" {
  value = module.global_resources.ACR_NAME
}

output "AZURE_STATIC_WEBAPP" {
  value = module.global_resources.AZURE_STATIC_WEBAPP_NAME
}