data "azurerm_application_insights" "cqrs" {
  name                = local.ai_name
  resource_group_name = local.global_rg_name
}

data "azurerm_log_analytics_workspace" "cqrs" {
  name                = local.logs_name
  resource_group_name = local.global_rg_name
}