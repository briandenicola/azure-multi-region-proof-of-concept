resource "azurerm_static_web_app" "ui" {
  count               = var.deploying_externally ? 1 : 0
  name                = local.static_webapp_name
  resource_group_name = azurerm_resource_group.cqrs_ui[0].name
  location            = local.static_webapp_location
  sku_size            = "Free"
  sku_tier            = "Free"
}
