terraform {
  required_providers {
    azurerm = "~> 2.21"
  }
}

provider "azurerm" {
  features  {}
}

resource "azurerm_resource_group" "cqrs_region" {
  count                 = length(var.locations)  
  name                  = "${var.application_name}_${var.locations[count.index]}_rg"
  location              = var.locations[count.index]
}

resource "azurerm_virtual_network" "cqrs_region" {
  count               = length(var.locations)  
  name                = "${var.vnet_name}${count.index+1}"
  location            = azurerm_resource_group.cqrs_region[count.index].location
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  address_space       = ["10.${count.index+1}.0.0/16"]

  subnet {
    name           = "AppGateway"
    address_prefix = "10.${count.index+1}.1.0/24"
  }

  subnet {
    name           = "APIM"
    address_prefix = "10.${count.index+1}.2.0/24"
  }

  subnet {
    name           = "Kubernetes"
    address_prefix = "10.${count.index+1}.4.0/22"
  }

  subnet {
    name           = "databricks-private"
    address_prefix = "10.${count.index+1}.10.0/24"
  }

  subnet {
    name           = "databricks-public"
    address_prefix = "10.${count.index+1}.11.0/24"
  }
}

resource "azurerm_subnet" "private-endpoints" {
  count                 = length(var.locations)  
  name                  = "private-endpoints"
  resource_group_name   = azurerm_virtual_network.cqrs_region[count.index].resource_group_name
  virtual_network_name  = azurerm_virtual_network.cqrs_region[count.index].name
  address_prefixes      = ["10.${count.index+1}.20.0/24"]

  enforce_private_link_endpoint_network_policies = false

}

resource "azurerm_eventhub_namespace" "cqrs_region" {
  count                     = length(var.locations)  
  name                      = "${var.eventhub_namespace_name}${count.index+1}"
  location                  = azurerm_resource_group.cqrs_region[count.index].location
  resource_group_name       = azurerm_resource_group.cqrs_region[count.index].name
  sku                       = "Standard"
  maximum_throughput_units  = 5
  auto_inflate_enabled      = true
}

resource "azurerm_eventhub" "cqrs_region" {
  count                 = length(var.locations)
  name                  = "events"
  namespace_name        = azurerm_eventhub_namespace.cqrs_region[count.index].name
  resource_group_name   = azurerm_resource_group.cqrs_region[count.index].name
  partition_count       = 15
  message_retention     = 7
}

resource "azurerm_redis_cache" "cqrs_region" {
  count               = length(var.locations)
  name                = "${var.redis_name}${count.index+1}"
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

resource "azurerm_storage_account" "cqrs_region" {
  count                    = length(var.locations)
  name                     = "${var.storage_name}${count.index+1}"
  resource_group_name      = azurerm_resource_group.cqrs_region[count.index].name
  location                 = azurerm_resource_group.cqrs_region[count.index].location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}
