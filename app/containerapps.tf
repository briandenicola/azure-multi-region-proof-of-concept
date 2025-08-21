module "container_apps" {
  for_each            = toset(var.locations)
  source              = "./apps"
  location            = each.value
  app_name            = var.app_name
  commit_version      = var.commit_version
  custom_domain       = var.custom_domain
  deploy_utils        = true
  use_cache           = var.use_cache
  ingress_domain_name = null
  tags                = var.tags
  authorized_ip_ranges = local.authorized_ip_ranges
}
