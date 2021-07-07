locals {
  subnets = [for location in var.locations : cidrsubnet("10.0.0.0/8", 8, index(var.locations, location) + 1)]
}

resource "azurerm_resource_group" "cqrs_region" {
  count    = length(var.locations)
  name     = "${var.application_name}_${var.locations[count.index]}_rg"
  location = var.locations[count.index]
  tags = {
    Application = var.application_name
  }
}

resource "azurerm_virtual_network" "cqrs_region" {
  count               = length(var.locations)
  name                = "${var.vnet_name}${count.index + 1}"
  location            = azurerm_resource_group.cqrs_region[count.index].location
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  address_space       = [local.subnets[count.index]]
}

resource "azurerm_subnet" "AzureFirewall" {
  count                = length(var.locations)
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_virtual_network.cqrs_region[count.index].resource_group_name
  virtual_network_name = azurerm_virtual_network.cqrs_region[count.index].name
  address_prefixes     = [cidrsubnet(local.subnets[count.index], 8, 0)]
}

resource "azurerm_subnet" "AppGateway" {
  count                = length(var.locations)
  name                 = "AppGateway"
  resource_group_name  = azurerm_virtual_network.cqrs_region[count.index].resource_group_name
  virtual_network_name = azurerm_virtual_network.cqrs_region[count.index].name
  address_prefixes     = [cidrsubnet(local.subnets[count.index], 8, 1)]
}

resource "azurerm_subnet" "APIM" {
  count                = length(var.locations)
  name                 = "APIM"
  resource_group_name  = azurerm_virtual_network.cqrs_region[count.index].resource_group_name
  virtual_network_name = azurerm_virtual_network.cqrs_region[count.index].name
  address_prefixes     = [cidrsubnet(local.subnets[count.index], 8, 2)]
}

resource "azurerm_subnet" "databricks-private" {
  count                = length(var.locations)
  name                 = "databricks-private"
  resource_group_name  = azurerm_virtual_network.cqrs_region[count.index].resource_group_name
  virtual_network_name = azurerm_virtual_network.cqrs_region[count.index].name
  address_prefixes     = [cidrsubnet(local.subnets[count.index], 8, 3)]
}

resource "azurerm_subnet" "databricks-public" {
  count                = length(var.locations)
  name                 = "databricks-public"
  resource_group_name  = azurerm_virtual_network.cqrs_region[count.index].resource_group_name
  virtual_network_name = azurerm_virtual_network.cqrs_region[count.index].name
  address_prefixes     = [cidrsubnet(local.subnets[count.index], 8, 4)]
}

resource "azurerm_subnet" "private-endpoints" {
  count                = length(var.locations)
  name                 = "private-endpoints"
  resource_group_name  = azurerm_virtual_network.cqrs_region[count.index].resource_group_name
  virtual_network_name = azurerm_virtual_network.cqrs_region[count.index].name
  address_prefixes     = [cidrsubnet(local.subnets[count.index], 8, 5)]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "kubernetes" {
  count                = length(var.locations)
  name                 = "Kubernetes"
  resource_group_name  = azurerm_virtual_network.cqrs_region[count.index].resource_group_name
  virtual_network_name = azurerm_virtual_network.cqrs_region[count.index].name
  address_prefixes     = [cidrsubnet(local.subnets[count.index], 6, 3)]
}

resource "azurerm_subnet_route_table_association" "cqrs_region" {
  count          = length(var.locations)
  subnet_id      = azurerm_subnet.kubernetes[count.index].id
  route_table_id = azurerm_route_table.cqrs_region[count.index].id
}

resource "azurerm_eventhub_namespace" "cqrs_region" {
  count                    = length(var.locations)
  name                     = "${var.eventhub_namespace_name}${count.index + 1}"
  location                 = azurerm_resource_group.cqrs_region[count.index].location
  resource_group_name      = azurerm_resource_group.cqrs_region[count.index].name
  sku                      = "Standard"
  maximum_throughput_units = 5
  auto_inflate_enabled     = true
}

resource "azurerm_eventhub" "cqrs_region" {
  count               = length(var.locations)
  name                = "events"
  namespace_name      = azurerm_eventhub_namespace.cqrs_region[count.index].name
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  partition_count     = 15
  message_retention   = 7
}

resource "azurerm_redis_cache" "cqrs_region" {
  count               = length(var.locations)
  name                = "${var.redis_name}${count.index + 1}"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  location            = azurerm_resource_group.cqrs_region[count.index].location
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }
}

resource "azurerm_public_ip" "cqrs_region" {
  count               = length(var.locations)
  name                = "${var.firewall_name}${count.index + 1}-ip"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  location            = azurerm_resource_group.cqrs_region[count.index].location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_table" "cqrs_region" {
  count                         = length(var.locations)
  name                          = "${var.firewall_name}${count.index + 1}-routetable"
  resource_group_name           = azurerm_resource_group.cqrs_region[count.index].name
  location                      = azurerm_resource_group.cqrs_region[count.index].location
  disable_bgp_route_propagation = true

  route {
    name                   = "DefaultRoute"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.cqrs_region[0].ip_configuration[0].private_ip_address
  }

  route {
    name           = "FirewallIP"
    address_prefix = "${azurerm_public_ip.cqrs_region[0].ip_address}/32"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_kubernetes_cluster" "cqrs_region" {
  count                           = length(var.locations)
  depends_on                      = [ azurerm_route_table.cqrs_region, azurerm_firewall_policy_rule_collection_group.cqrs_region ]
  name                            = "${var.aks_name}${count.index + 1}"
  resource_group_name             = azurerm_resource_group.cqrs_region[count.index].name
  location                        = azurerm_resource_group.cqrs_region[count.index].location
  node_resource_group             = "${azurerm_resource_group.cqrs_region[count.index].name}_k8s_nodes"
  dns_prefix                      = "${var.aks_name}${count.index + 1}"
  sku_tier                        = "Paid"
  api_server_authorized_ip_ranges = [var.api_server_authorized_ip_ranges]
  linux_profile {
    admin_username = "manager"

    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                = "default"
    node_count          = 3
    vm_size             = "Standard_B4ms"
    os_disk_size_gb     = 30
    vnet_subnet_id      = azurerm_subnet.kubernetes[count.index].id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 10
    max_pods            = 40
  }

  role_based_access_control {
    enabled = "true"
  }

  network_profile {
    dns_service_ip     = "10.19${count.index}.0.10"
    service_cidr       = "10.19${count.index}.0.0/16"
    docker_bridge_cidr = "172.17.0.1/16"
    network_plugin     = "azure"
    load_balancer_sku  = "standard"
    outbound_type      = "userDefinedRouting"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.cqrs_logs.id
    }
  }

}

resource "azurerm_role_assignment" "acr_pullrole_node" {
  count                            = length(var.locations)
  scope                            = azurerm_container_registry.cqrs_acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.cqrs_region[count.index].kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acr_pullrole_cluster" {
  count                            = length(var.locations)
  scope                            = azurerm_container_registry.cqrs_acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.cqrs_region[count.index].identity.0.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "network_contributor_cluster" {
  count                            = length(var.locations)
  scope                            = azurerm_resource_group.cqrs_region[count.index].id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_kubernetes_cluster.cqrs_region[count.index].kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "network_contributor_node" {
  count                            = length(var.locations)
  scope                            = azurerm_resource_group.cqrs_region[count.index].id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_kubernetes_cluster.cqrs_region[count.index].identity.0.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_private_dns_zone" "privatelink_azurecr_io" {
  count                     = length(var.locations)
  name                      = "privatelink.azurecr.io"
  resource_group_name       = azurerm_resource_group.cqrs_region[count.index].name
}


resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_azurecr_io" {
  count                 = length(var.locations)
  name                  = "${azurerm_virtual_network.cqrs_region[count.index].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_azurecr_io[count.index].name
  resource_group_name   = azurerm_resource_group.cqrs_region[count.index].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[count.index].id
}

resource "azurerm_private_dns_zone" "privatelink_documents_azure_com" {
  count               = length(var.locations)
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_documents_azure_com" {
  count                 = length(var.locations)
  name                  = "${azurerm_virtual_network.cqrs_region[count.index].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_documents_azure_com[count.index].name
  resource_group_name   = azurerm_resource_group.cqrs_region[count.index].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[count.index].id
}

resource "azurerm_private_dns_zone" "privatelink_blob_core_windows_net" {
  count               = length(var.locations)
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_blob_core_windows_net" {
  count                 = length(var.locations)
  name                  = "${azurerm_virtual_network.cqrs_region[count.index].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_blob_core_windows_net[count.index].name
  resource_group_name   = azurerm_resource_group.cqrs_region[count.index].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[count.index].id
}

resource "azurerm_private_dns_zone" "privatelink_servicebus_windows_net" {
  count               = length(var.locations)
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_servicebus_windows_net" {
  count                 = length(var.locations)
  name                  = "${azurerm_virtual_network.cqrs_region[count.index].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_servicebus_windows_net[count.index].name
  resource_group_name   = azurerm_resource_group.cqrs_region[count.index].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[count.index].id
}

resource "azurerm_private_dns_zone" "privatelink_redis_cache_windows_net" {
  count               = length(var.locations)
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_redis_cache_windows_net" {
  count                 = length(var.locations)
  name                  = "${azurerm_virtual_network.cqrs_region[count.index].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_redis_cache_windows_net[count.index].name
  resource_group_name   = azurerm_resource_group.cqrs_region[count.index].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[count.index].id
}

resource "azurerm_private_dns_zone" "custom_domain" {
  count               = length(var.locations)
  name                = var.custom_domain
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "custom_domain" {
  count                 = length(var.locations)
  name                  = "${azurerm_virtual_network.cqrs_region[count.index].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.custom_domain[count.index].name
  resource_group_name   = azurerm_resource_group.cqrs_region[count.index].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[count.index].id
}

resource "azurerm_private_endpoint" "cosmos_db" {
  count               = length(var.locations)
  name                = "${var.cosmosdb_name}-${var.locations[count.index]}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  location            = azurerm_resource_group.cqrs_region[count.index].location
  subnet_id           = azurerm_subnet.private-endpoints[count.index].id

  private_service_connection {
    name                           = "${var.cosmosdb_name}-${var.locations[count.index]}-ep"
    private_connection_resource_id = azurerm_cosmosdb_account.cqrs_db.id
    subresource_names              = ["sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_documents_azure_com[count.index].name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_documents_azure_com[count.index].id]
  }
}

resource "azurerm_private_endpoint" "eventhub_namespace" {
  count               = length(var.locations)
  name                = "${var.eventhub_namespace_name}-${var.locations[count.index]}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  location            = azurerm_resource_group.cqrs_region[count.index].location
  subnet_id           = azurerm_subnet.private-endpoints[count.index].id

  private_service_connection {
    name                           = "${var.eventhub_namespace_name}-${var.locations[count.index]}-ep"
    private_connection_resource_id = azurerm_eventhub_namespace.cqrs_region[count.index].id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_servicebus_windows_net[count.index].name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_servicebus_windows_net[count.index].id]
  }
}

resource "azurerm_private_endpoint" "redis_account" {
  count               = length(var.locations)
  name                = "${var.redis_name}-${var.locations[count.index]}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  location            = azurerm_resource_group.cqrs_region[count.index].location
  subnet_id           = azurerm_subnet.private-endpoints[count.index].id

  private_service_connection {
    name                           = "${var.redis_name}-${var.locations[count.index]}-ep"
    private_connection_resource_id = azurerm_redis_cache.cqrs_region[count.index].id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_redis_cache_windows_net[count.index].name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_redis_cache_windows_net[count.index].id]
  }
}

resource "azurerm_private_endpoint" "acr_account" {
  count               = length(var.locations)
  name                = "${var.acr_account_name}-${var.locations[count.index]}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  location            = azurerm_resource_group.cqrs_region[count.index].location
  subnet_id           = azurerm_subnet.private-endpoints[count.index].id

  private_service_connection {
    name                           = "${var.acr_account_name}-${var.locations[count.index]}-ep"
    private_connection_resource_id = azurerm_container_registry.cqrs_acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_azurecr_io[count.index].name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_azurecr_io[count.index].id]
  }
}

