resource "azurerm_public_ip" "firewall" {
  name                = "${local.firewall_name}-pip"
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = azurerm_resource_group.cqrs_region.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "cqrs" {
  name                = local.firewall_name
  resource_group_name = azurerm_resource_group.cqrs_region.name
  location            = azurerm_resource_group.cqrs_region.location
  firewall_policy_id  = azurerm_firewall_policy.cqrs.id
  sku_tier            = "Standard"
  sku_name            = "AZFW_VNet"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.AzureFirewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag"
  target_resource_id         = azurerm_firewall.cqrs.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.cqrs.id

  enabled_log {
    category = "AzureFirewallApplicationRule"

  }

  enabled_log {
    category = "AzureFirewallNetworkRule"

  }

  enabled_log {
    category = "AzureFirewallDnsProxy"

  }

  metric {
    category = "AllMetrics"
  }
}
