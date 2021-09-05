locals {
  subnets = [for location in var.locations : cidrsubnet("10.0.0.0/8", 8, index(var.locations, location) + 1)]
  locations_set = toset(var.locations)
}

resource "azurerm_resource_group" "cqrs_region" {
  for_each = local.locations_set
  name     = "${var.application_name}_${each.key}_rg"
  location = each.key
  tags     = {
    Application = "cqrs"
    Version     = var.application_name
    Components  = "regional"
    DeployedOn  = timestamp()
  }
}

resource "azurerm_network_security_group" "cqrs_region" {
  for_each            = local.locations_set
  name                = "${var.vnet_name}${index(var.locations,each.key)+1}-default-nsg"
  location            = azurerm_resource_group.cqrs_region[each.key].location
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
}

resource "azurerm_virtual_network" "cqrs_region" {
  for_each            = local.locations_set
  name                = "${var.vnet_name}${index(var.locations,each.key)+1}"
  location            = azurerm_resource_group.cqrs_region[each.key].location
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
  address_space       = [local.subnets[index(var.locations,each.key)]]
}

resource "azurerm_subnet" "AzureFirewall" {
  for_each              = local.locations_set
  name                  = "AzureFirewallSubnet"
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_name  = azurerm_virtual_network.cqrs_region[each.key].name
  address_prefixes      = [cidrsubnet(local.subnets[index(var.locations,each.key)], 8, 0)]
}

resource "azurerm_subnet" "AppGateway" {
  for_each              = local.locations_set
  name                  = "AppGateway"
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_name  = azurerm_virtual_network.cqrs_region[each.key].name
  address_prefixes      = [cidrsubnet(local.subnets[index(var.locations,each.key)], 8, 1)]
}

resource "azurerm_subnet" "APIM" {
  for_each              = local.locations_set
  name                  = "APIM"
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_name  = azurerm_virtual_network.cqrs_region[each.key].name
  address_prefixes      = [cidrsubnet(local.subnets[index(var.locations,each.key)], 8, 2)]
}

resource "azurerm_subnet_network_security_group_association" "apim_subnet" {
  for_each                  = local.locations_set
  subnet_id                 = azurerm_subnet.APIM[each.key].id
  network_security_group_id = azurerm_network_security_group.cqrs_region[each.key].id
}

resource "azurerm_subnet" "databricks-private" {
  for_each              = local.locations_set
  name                  = "databricks-private"
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_name  = azurerm_virtual_network.cqrs_region[each.key].name
  address_prefixes      = [cidrsubnet(local.subnets[index(var.locations,each.key)], 8, 3)]
}

resource "azurerm_subnet_network_security_group_association" "databricks-private_subnet" {
  for_each                  = local.locations_set
  subnet_id                 = azurerm_subnet.databricks-private[each.key].id
  network_security_group_id = azurerm_network_security_group.cqrs_region[each.key].id
}

resource "azurerm_subnet" "databricks-public" {
  for_each              = local.locations_set
  name                  = "databricks-public"
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_name  = azurerm_virtual_network.cqrs_region[each.key].name
  address_prefixes      = [cidrsubnet(local.subnets[index(var.locations,each.key)], 8, 4)]
}

resource "azurerm_subnet_network_security_group_association" "databricks-public_subnet" {
  for_each                  = local.locations_set
  subnet_id                 = azurerm_subnet.databricks-public[each.key].id
  network_security_group_id = azurerm_network_security_group.cqrs_region[each.key].id
}

resource "azurerm_subnet" "private-endpoints" {
  for_each            = local.locations_set
  name                 = "private-endpoints"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_name  = azurerm_virtual_network.cqrs_region[each.key].name
  address_prefixes     = [cidrsubnet(local.subnets[index(var.locations,each.key)], 8, 5)]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet_network_security_group_association" "private-endpoints_subnet" {
  for_each                  = local.locations_set
  subnet_id                 = azurerm_subnet.private-endpoints[each.key].id
  network_security_group_id = azurerm_network_security_group.cqrs_region[each.key].id
}

resource "azurerm_subnet" "kubernetes" {
  for_each              = local.locations_set
  name                  = "Kubernetes"
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_name  = azurerm_virtual_network.cqrs_region[each.key].name
  address_prefixes      = [cidrsubnet(local.subnets[index(var.locations,each.key)], 6, 3)]
}

resource "azurerm_subnet_route_table_association" "cqrs_region" {
  for_each              = local.locations_set
  subnet_id             = azurerm_subnet.kubernetes[each.key].id
  route_table_id        = azurerm_route_table.cqrs_region[each.key].id
}

resource "azurerm_eventhub_namespace" "cqrs_region" {
  for_each                 = local.locations_set
  name                     = "${var.eventhub_namespace_name}${index(var.locations,each.key)+1}"
  location                 = azurerm_resource_group.cqrs_region[each.key].location
  resource_group_name      = azurerm_resource_group.cqrs_region[each.key].name
  sku                      = "Standard"
  maximum_throughput_units = 5
  auto_inflate_enabled     = true
}

resource "azurerm_eventhub" "cqrs_region" {
  for_each              = local.locations_set
  name                  = "events"
  namespace_name        = azurerm_eventhub_namespace.cqrs_region[each.key].name
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  partition_count       = 15
  message_retention     = 7
}

resource "azurerm_redis_cache" "cqrs_region" {
  for_each              = local.locations_set
  name                  = "${var.redis_name}${index(var.locations,each.key)+1}"
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  location              = azurerm_resource_group.cqrs_region[each.key].location
  capacity              = 1
  family                = "C"
  sku_name              = "Standard"
  enable_non_ssl_port   = false
  minimum_tls_version   = "1.2"

  redis_configuration {
  }
}

resource "azurerm_storage_account" "cqrs_region" {
  for_each                 = local.locations_set
  name                     = "${var.storage_name}${index(var.locations,each.key)+1}"
  resource_group_name      = azurerm_resource_group.cqrs_region[each.key].name
  location                 = azurerm_resource_group.cqrs_region[each.key].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_public_ip" "firewall" {
  for_each            = local.locations_set
  name                = "${var.firewall_name}${index(var.locations,each.key)+1}-ip"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
  location            = azurerm_resource_group.cqrs_region[each.key].location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_table" "cqrs_region" {
  for_each                        = local.locations_set
  name                            = "${var.firewall_name}${index(var.locations,each.key)+1}-routetable"
  resource_group_name             = azurerm_resource_group.cqrs_region[each.key].name
  location                        = azurerm_resource_group.cqrs_region[each.key].location
  disable_bgp_route_propagation   = true

  route {
    name                          = "DefaultRoute"
    address_prefix                = "0.0.0.0/0"
    next_hop_type                 = "VirtualAppliance"
    next_hop_in_ip_address        = azurerm_firewall.cqrs_region[each.key].ip_configuration[0].private_ip_address
  }

  route {
    name                          = "FirewallIP"
    address_prefix                = "${azurerm_public_ip.firewall[each.key].ip_address}/32"
    next_hop_type                 = "Internet"
  }
}

resource "azurerm_kubernetes_cluster" "cqrs_region" {
  for_each                        = local.locations_set
  depends_on                      = [ azurerm_route_table.cqrs_region, azurerm_firewall_policy_rule_collection_group.cqrs_region ]
  name                            = "${var.aks_name}${index(var.locations,each.key)+1}"
  resource_group_name             = azurerm_resource_group.cqrs_region[each.key].name
  location                        = azurerm_resource_group.cqrs_region[each.key].location
  node_resource_group             = "${azurerm_resource_group.cqrs_region[each.key].name}_k8s_nodes"
  dns_prefix                      = "${var.aks_name}${index(var.locations,each.key)+1}"
  sku_tier                        = "Paid"
  api_server_authorized_ip_ranges = [var.api_server_authorized_ip_ranges, "${azurerm_public_ip.firewall[each.key].ip_address}/32"]
  automatic_channel_upgrade       = "patch"

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
    vnet_subnet_id      = azurerm_subnet.kubernetes[each.key].id
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
    dns_service_ip     = "10.19${index(var.locations,each.key)}.0.10"
    service_cidr       = "10.19${index(var.locations,each.key)}.0.0/16"
    docker_bridge_cidr = "172.17.0.1/16"
    network_plugin     = "azure"
    load_balancer_sku  = "standard"
    outbound_type      = "userDefinedRouting"
    network_policy     = "calico"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.cqrs_logs.id
    }
    azure_policy {
      enabled                   = "true"
    }
  }

}

resource "azurerm_role_assignment" "acr_pullrole_node" {
  for_each                         = local.locations_set
  scope                            = azurerm_container_registry.cqrs_acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.cqrs_region[each.key].kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acr_pullrole_cluster" {
  for_each                         = local.locations_set
  scope                            = azurerm_container_registry.cqrs_acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.cqrs_region[each.key].identity.0.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "network_contributor_cluster" {
  for_each                         = local.locations_set
  scope                            = azurerm_resource_group.cqrs_region[each.key].id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_kubernetes_cluster.cqrs_region[each.key].kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "network_contributor_node" {
  for_each                         = local.locations_set
  scope                            = azurerm_resource_group.cqrs_region[each.key].id
  role_definition_name             = "Network Contributor"
  principal_id                     = azurerm_kubernetes_cluster.cqrs_region[each.key].identity.0.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_private_dns_zone" "privatelink_azurecr_io" {
  for_each                  = local.locations_set
  name                      = "privatelink.azurecr.io"
  resource_group_name       = azurerm_resource_group.cqrs_region[each.key].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_azurecr_io" {
  for_each              = local.locations_set
  name                  = "${azurerm_virtual_network.cqrs_region[each.key].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_azurecr_io[each.key].name
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[each.key].id
}

resource "azurerm_private_dns_zone" "privatelink_documents_azure_com" {
  for_each            = local.locations_set
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_documents_azure_com" {
  for_each              = local.locations_set
  name                  = "${azurerm_virtual_network.cqrs_region[each.key].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_documents_azure_com[each.key].name
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[each.key].id
}

resource "azurerm_private_dns_zone" "privatelink_blob_core_windows_net" {
  for_each            = local.locations_set
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_blob_core_windows_net" {
  for_each              = local.locations_set
  name                  = "${azurerm_virtual_network.cqrs_region[each.key].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_blob_core_windows_net[each.key].name
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[each.key].id
}

resource "azurerm_private_dns_zone" "privatelink_servicebus_windows_net" {
  for_each            = local.locations_set
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_servicebus_windows_net" {
  for_each              = local.locations_set
  name                  = "${azurerm_virtual_network.cqrs_region[each.key].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_servicebus_windows_net[each.key].name
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[each.key].id
}

resource "azurerm_private_dns_zone" "privatelink_redis_cache_windows_net" {
  for_each            = local.locations_set
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_redis_cache_windows_net" {
  for_each              = local.locations_set
  name                  = "${azurerm_virtual_network.cqrs_region[each.key].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.privatelink_redis_cache_windows_net[each.key].name
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[each.key].id
}

resource "azurerm_private_dns_zone" "custom_domain" {
  for_each            = local.locations_set
  name                = var.custom_domain
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
}

resource "azurerm_private_dns_zone_virtual_network_link" "custom_domain" {
  for_each              = local.locations_set
  name                  = "${azurerm_virtual_network.cqrs_region[each.key].name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.custom_domain[each.key].name
  resource_group_name   = azurerm_resource_group.cqrs_region[each.key].name
  virtual_network_id    = azurerm_virtual_network.cqrs_region[each.key].id
}

resource "azurerm_private_endpoint" "storage_account" {
  for_each                  = local.locations_set
  name                      = "${var.storage_name}-${each.key}-ep"
  resource_group_name       = azurerm_resource_group.cqrs_region[each.key].name
  location                  = azurerm_resource_group.cqrs_region[each.key].location
  subnet_id                 = azurerm_subnet.private-endpoints[each.key].id

  private_service_connection {
    name                           = "${var.storage_name}-${each.key}-ep"
    private_connection_resource_id = azurerm_storage_account.cqrs_region[each.key].id
    subresource_names              = [ "blob" ]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                          = azurerm_private_dns_zone.privatelink_blob_core_windows_net[each.key].name
    private_dns_zone_ids          = [ azurerm_private_dns_zone.privatelink_blob_core_windows_net[each.key].id ]
  }
}

resource "azurerm_private_endpoint" "cosmos_db" {
  for_each            = local.locations_set
  name                = "${var.cosmosdb_name}-${each.key}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
  location            = azurerm_resource_group.cqrs_region[each.key].location
  subnet_id           = azurerm_subnet.private-endpoints[each.key].id

  private_service_connection {
    name                           = "${var.cosmosdb_name}-${each.key}-ep"
    private_connection_resource_id = azurerm_cosmosdb_account.cqrs_db.id
    subresource_names              = ["sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_documents_azure_com[each.key].name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_documents_azure_com[each.key].id]
  }
}

resource "azurerm_private_endpoint" "eventhub_namespace" {
  for_each            = local.locations_set
  name                = "${var.eventhub_namespace_name}-${each.key}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
  location            = azurerm_resource_group.cqrs_region[each.key].location
  subnet_id           = azurerm_subnet.private-endpoints[each.key].id

  private_service_connection {
    name                           = "${var.eventhub_namespace_name}-${each.key}-ep"
    private_connection_resource_id = azurerm_eventhub_namespace.cqrs_region[each.key].id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_servicebus_windows_net[each.key].name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_servicebus_windows_net[each.key].id]
  }
}

resource "azurerm_private_endpoint" "redis_account" {
  for_each            = local.locations_set
  name                = "${var.redis_name}-${each.key}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
  location            = azurerm_resource_group.cqrs_region[each.key].location
  subnet_id           = azurerm_subnet.private-endpoints[each.key].id

  private_service_connection {
    name                           = "${var.redis_name}-${each.key}-ep"
    private_connection_resource_id = azurerm_redis_cache.cqrs_region[each.key].id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_redis_cache_windows_net[each.key].name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_redis_cache_windows_net[each.key].id]
  }
}

resource "azurerm_private_endpoint" "acr_account" {
  for_each            = local.locations_set
  name                = "${var.acr_account_name}-${each.key}-ep"
  resource_group_name = azurerm_resource_group.cqrs_region[each.key].name
  location            = azurerm_resource_group.cqrs_region[each.key].location
  subnet_id           = azurerm_subnet.private-endpoints[each.key].id

  private_service_connection {
    name                           = "${var.acr_account_name}-${each.key}-ep"
    private_connection_resource_id = azurerm_container_registry.cqrs_acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.privatelink_azurecr_io[each.key].name
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_azurecr_io[each.key].id]
  }
}

