resource "azurerm_firewall" "cqrs_region" {
  count               = length(var.locations)
  name                = "${var.firewall_name}${count.index + 1}"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  location            = azurerm_resource_group.cqrs_region[count.index].location
  firewall_policy_id  = azurerm_firewall_policy.cqrs_region[count.index].id

  ip_configuration {
    name                 = "confiugration"
    subnet_id            = azurerm_subnet.AzureFirewall[count.index].id
    public_ip_address_id = azurerm_public_ip.cqrs_region[count.index].id
  }
}

resource "azurerm_firewall_policy" "cqrs_region" {
  count               = length(var.locations)
  name                = "${var.firewall_name}${count.index + 1}-policies"
  resource_group_name = azurerm_resource_group.cqrs_region[count.index].name
  location            = azurerm_resource_group.cqrs_region[count.index].location
  sku                 = "Standard"

  dns {
    proxy_enabled     = true
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "cqrs_region" {
  count                 = length(var.locations)
  name                  = "${var.firewall_name}${count.index + 1}_rules_collection"
  firewall_policy_id    = azurerm_firewall_policy.cqrs_region[count.index].id

  priority              = 200

  application_rule_collection {
    name                = "app_rule_collection"
    priority            = 500
    action              = "Allow"

    rule {
        name              = "hcp"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "*.hcp.${azurerm_resource_group.cqrs_region[count.index].location}.azmk8s.io"
        ]
    }

    rule {
        name              = "mcr"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "mcr.microsoft.com"
        ]
    }

    rule {
        name              = "mcr-data"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "*.data.mcr.microsoft.com"
        ]
    }        

    rule {
        name              = "management"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "management.microsoft.com"
        ]
    }  

    rule {
        name              = "login"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "login.microsoftonline.com"
        ]
    } 

    rule {
        name              = "packages"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "packages.microsoft.com"
        ]
    }

    rule {
        name              = "acs-mirror"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "acs-mirror.azureedge.net"
        ]
    }

    rule {
        name              = "docker"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "*.docker.io"
        ]
    } 

    rule {
        name              = "dc-services"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "dc.services.visualstudio.com"
        ]
    }

    rule {
        name              = "ods"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "*.ods.opinsights.azure.com"
        ]
    }

    rule {
        name              = "oms"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "*.oms.opinsights.azure.com"
        ]
    }

    rule {
        name              = "monitoring-url"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "*.monitoring.azure.com"
        ]
    }

    rule {
        name              = "data-policy"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "data.policy.core.windows.net"
        ]
    }

    rule {
        name              = "store"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "store.policy.core.windows.net"
        ]
    }

    rule {
        name              = "acr"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            azurerm_container_registry.cqrs_acr.login_server
        ]
    }

    rule {
        name              = "acr-data"
        source_addresses  = ["*"]
      
        protocols {
            port            = "443"
            type            = "HTTPS"
        }

        destination_fqdns = [
            "${var.acr_account_name}.${azurerm_resource_group.cqrs_region[count.index].location}.data.azurecr.io"
        ]
    }

    rule {
      name                  = "aks"
      source_addresses      = ["*"]

      protocols {
        port                = "443"
        type                = "HTTPS"
      }

      protocols {
        port                = "80"
        type                = "HTTP"
      }

      destination_fqdn_tags = [
        "AzureKubernetesService"
      ]
    }

    rule {
      name                  = "security"
      source_addresses      = ["*"]

      protocols {
        port                = "80"
        type                = "HTTP"
      }

      protocols {
        port                = "443"
        type                = "HTTPS"
      }

      destination_fqdns     = [
        "security.ubuntu.com"
      ]
    }

    rule {
      name                  = "archive"
      source_addresses      = ["*"]

      protocols {
        port                = "80"
        type                = "HTTP"
      }

      protocols {
        port                = "443"
        type                = "HTTPS"
      }

      destination_fqdns     = [
        "azure.archive.ubuntu.com"
      ]
    }

    rule {
      name                  = "changelogs"
      source_addresses      = ["*"]

      protocols {
        port                = "80"
        type                = "HTTP"
      }

      protocols {
        port                = "443"
        type                = "HTTPS"
      }

      destination_fqdns     = [
        "changelogs.ubuntu.com"
      ]
    }
  }

  network_rule_collection {
    name                  = "network_rule_collection"
    priority              = 400
    action                = "Allow"

    rule {
      name              = "apiudp"
      source_addresses  = ["*"]
      destination_ports = ["1194"]
      protocols         = ["UDP"]
      destination_addresses = [
        "AzureCloud.${azurerm_resource_group.cqrs_region[count.index].location}"
      ]
    }

    rule {
      name              = "apitcp"
      source_addresses  = ["*"]
      destination_ports = ["9000"]
      protocols         = ["TCP"]
      destination_addresses = [
        "AzureCloud.${azurerm_resource_group.cqrs_region[count.index].location}"
      ]
    }

    rule {
      name              = "monitor"
      source_addresses  = ["*"]
      destination_ports = ["443"]
      protocols         = ["TCP"]
      destination_addresses = [
        "AzureMonitor"
      ]
    }

    rule {
      name              = "time"
      source_addresses  = ["*"]
      destination_ports = ["123"]
      protocols         = ["UDP"]
      destination_fqdns = [
        "ntp.ubuntu.com"
      ]
    }
  }
}
