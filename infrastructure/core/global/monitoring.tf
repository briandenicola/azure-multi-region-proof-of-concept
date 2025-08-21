
resource "azurerm_log_analytics_workspace" "this" {
  name                          = local.la_name
  resource_group_name           = azurerm_resource_group.global.name
  location                      = azurerm_resource_group.global.location
  local_authentication_enabled  = false
  sku                           = "PerGB2018"
  daily_quota_gb                = 10
}

resource "azurerm_application_insights" "this" {
  name                          = local.ai_name
  resource_group_name           = azurerm_resource_group.global.name
  location                      = azurerm_resource_group.global.location
  application_type              = "web"
  workspace_id                  = azurerm_log_analytics_workspace.this.id
  local_authentication_disabled = true
}
