data "azurerm_container_registry" "cqrs" {
  name                = local.acr_name
  resource_group_name = local.global_rg_name
}