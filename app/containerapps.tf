module "container_apps" {
  for_each       = toset(var.locations)
  source         = "./apps"
  location       = each.value
  app_name       = var.app_name
  commit_version = var.commit_version
  custom_domain  = var.custom_domain
  deploy_utils   = true
}
