
resource "azurerm_log_analytics_workspace" "cqrs" {
  name                          = local.la_name
  resource_group_name           = azurerm_resource_group.cqrs_global.name
  location                      = azurerm_resource_group.cqrs_global.location
  local_authentication_disabled = false
  sku                           = "PerGB2018"
  daily_quota_gb                = 10
}

resource "azurerm_application_insights" "cqrs" {
  name                          = local.ai_name
  resource_group_name           = azurerm_resource_group.cqrs_global.name
  location                      = azurerm_resource_group.cqrs_global.location
  application_type              = "web"
  workspace_id                  = azurerm_log_analytics_workspace.cqrs.id
  local_authentication_disabled = false
}
