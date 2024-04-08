data "azurerm_log_analytics_workspace" "cqrs_logs" {
  name                = local.la_name
  resource_group_name = local.global_rg_name
}

data "azurerm_application_insights" "cqrs_app_insights" {
  name                = local.ai_name
  resource_group_name = local.global_rg_name
}
