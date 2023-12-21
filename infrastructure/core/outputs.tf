output APP_NAME {
  value     = local.resource_name
  sensitive = false
}

output "APP_INGRESS_IPS" {
  value = [ for region in module.regional_resources : region.APP_INGRESS_IP ]
}
