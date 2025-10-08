locals {
  resource_group_name = var.deployment_prefix
  location            = var.location != "" ? var.location : "canadacentral"
  vnet_name           = var.vnet_name != "" ? var.vnet_name : "${var.deployment_prefix}-vnet"

  # Use manually specified IP or auto-detect
  detected_public_ip = var.my_public_ip != "" ? var.my_public_ip : "${trimspace(data.http.my_public_ip[0].response_body)}/32"

  #####################################################################
  # Resource Groups
  #####################################################################

  resource_groups = {
    (local.resource_group_name) = {
      name     = local.resource_group_name
      location = local.location
      tags     = var.fortinet_tags
    }
  }

  #####################################################################
  # Virtual Networks
  #####################################################################

  virtual_networks = {
    (local.vnet_name) = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name          = local.vnet_name
      address_space = [var.vnet_address_prefix]
      tags          = var.fortinet_tags
    }
  }

  #####################################################################
  # Subnets
  #####################################################################

  subnets = {
    "${var.deployment_prefix}-${var.subnets["fortigate_external"].name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnets["fortigate_external"].name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnets["fortigate_external"].address_prefix]
    }
    "${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnets["fortigate_internal"].name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnets["fortigate_internal"].address_prefix]
    }
    "${var.deployment_prefix}-${var.subnets["fortigate_ha"].name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnets["fortigate_ha"].name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnets["fortigate_ha"].address_prefix]
    }
    "${var.deployment_prefix}-${var.subnets["fortigate_management"].name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnets["fortigate_management"].name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnets["fortigate_management"].address_prefix]
    }
    "${var.deployment_prefix}-${var.subnets["fortiweb_external"].name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnets["fortiweb_external"].name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnets["fortiweb_external"].address_prefix]
    }
    "${var.deployment_prefix}-${var.subnets["fortiweb_internal"].name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnets["fortiweb_internal"].name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnets["fortiweb_internal"].address_prefix]
    }
    "${var.deployment_prefix}-${var.subnets["workload"].name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnets["workload"].name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnets["workload"].address_prefix]
    }
  }

  #####################################################################
  # Route Tables
  #####################################################################

  route_tables = {
    "${var.deployment_prefix}-rt-${var.subnets["workload"].name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-rt-${var.subnets["workload"].name}"
      tags = {
      }
    }
    "${var.deployment_prefix}-rt-${var.subnets["fortiweb_external"].name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-rt-${var.subnets["fortiweb_external"].name}"
      tags = {
      }
    }
  }

  #####################################################################
  # Routes
  # Routes for DMZ and FortiWeb subnets to send traffic through FortiGate Internal LB
  # References the Internal LB frontend IP attribute
  #####################################################################

  routes = merge(
    {
      "${var.deployment_prefix}-route-default-${var.subnets["workload"].name}" = {
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

        name                   = "toDefault"
        route_table_name       = "${var.deployment_prefix}-rt-${var.subnets["workload"].name}"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = azurerm_lb.load_balancer["${var.deployment_prefix}-internal-lb"].frontend_ip_configuration[0].private_ip_address
      }
    },
    var.on_prem_range != "" ? {
      "${var.deployment_prefix}-route-onprem-${var.subnets["fortiweb_external"].name}" = {
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

        name                   = "toOnPrem"
        route_table_name       = "${var.deployment_prefix}-rt-${var.subnets["fortiweb_external"].name}"
        address_prefix         = var.on_prem_range
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = azurerm_lb.load_balancer["${var.deployment_prefix}-internal-lb"].frontend_ip_configuration[0].private_ip_address
      }
    } : {}
  )

  #####################################################################
  # Subnet Route Table Associations
  #####################################################################

  subnet_route_table_associations = {
    "${var.deployment_prefix}-${var.subnets["workload"].name}-rt-association" = {
      subnet_id      = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["workload"].name}"].id
      route_table_id = azurerm_route_table.route_table["${var.deployment_prefix}-rt-${var.subnets["workload"].name}"].id
    }
    "${var.deployment_prefix}-${var.subnets["fortiweb_external"].name}-rt-association" = {
      subnet_id      = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortiweb_external"].name}"].id
      route_table_id = azurerm_route_table.route_table["${var.deployment_prefix}-rt-${var.subnets["fortiweb_external"].name}"].id
    }
  }

  #####################################################################
  # Network Security Groups
  #####################################################################

  network_security_groups = {
    "${var.deployment_prefix}-nsg-allow-all" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-nsg-allow-all"
      tags = {
      }

      security_rules = [
        {
          name                       = "AllowAllInbound"
          description                = "Allow all in"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowAllOutbound"
          description                = "Allow all out"
          priority                   = 105
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }

    "${var.deployment_prefix}-nsg-mgmt" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-nsg-mgmt"
      tags = var.fortinet_tags

      security_rules = [
        {
          name                       = "AllowHTTPSFromMyIP"
          description                = "Allow HTTPS from detected public IP"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = tostring(var.port_https)
          source_address_prefix      = local.detected_public_ip
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowSSHFromMyIP"
          description                = "Allow SSH from detected public IP"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = tostring(var.port_ssh)
          source_address_prefix      = local.detected_public_ip
          destination_address_prefix = "*"
        }
      ]
    }

    "${var.deployment_prefix}-nsg-fortiweb" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-nsg-fortiweb"
      tags = var.fortinet_tags

      security_rules = [
        {
          name                       = "AllowSSHInbound"
          description                = "Allow SSH In"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = tostring(var.port_ssh)
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowHTTPInbound"
          description                = "Allow ${var.port_http} In"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = tostring(var.port_http)
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowHTTPSInbound"
          description                = "Allow ${var.port_https} In"
          priority                   = 120
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = tostring(var.port_https)
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowDevRegInbound"
          description                = "Allow ${var.port_syslog} in for device registration"
          priority                   = 130
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = tostring(var.port_syslog)
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowMgmtHTTPInbound"
          description                = "Allow ${var.fortiweb_http_probe_port} In"
          priority                   = 140
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = tostring(var.fortiweb_http_probe_port)
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowMgmtHTTPSInbound"
          description                = "Allow ${var.fortiweb_https_probe_port} In"
          priority                   = 150
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = tostring(var.fortiweb_https_probe_port)
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowAllOutbound"
          description                = "Allow all out"
          priority                   = 105
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
  }

  #####################################################################
  # Network Interface Security Group Associations
  # Associate NSGs with FortiGate NICs:
  # - nsg-allow-all on port1 (External) for both FortiGates
  # - nsg-mgmt on port4 (Management) when public IPs enabled
  # Associate NSGs with FortiWeb NICs:
  # - nsg-fortiweb on port1 (External) for both FortiWebs
  #####################################################################

  network_interface_security_group_associations = merge(
    # Always associate nsg-allow-all with FortiGate External NICs (port1)
    {
      "${var.deployment_prefix}-fgt-a-nic1-nsg-assoc" = {
        network_interface_id      = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic1"].id
        network_security_group_id = azurerm_network_security_group.network_security_group["${var.deployment_prefix}-nsg-allow-all"].id
      }
      "${var.deployment_prefix}-fgt-b-nic1-nsg-assoc" = {
        network_interface_id      = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic1"].id
        network_security_group_id = azurerm_network_security_group.network_security_group["${var.deployment_prefix}-nsg-allow-all"].id
      }
    },
    # Conditionally associate nsg-mgmt with FortiGate Management NICs (port4)
    var.enable_fortigate_mgmt_public_ips ? {
      "${var.deployment_prefix}-fgt-a-nic4-nsg-assoc" = {
        network_interface_id      = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic4"].id
        network_security_group_id = azurerm_network_security_group.network_security_group["${var.deployment_prefix}-nsg-mgmt"].id
      }
      "${var.deployment_prefix}-fgt-b-nic4-nsg-assoc" = {
        network_interface_id      = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic4"].id
        network_security_group_id = azurerm_network_security_group.network_security_group["${var.deployment_prefix}-nsg-mgmt"].id
      }
    } : {},
    # Conditionally associate nsg-fortiweb with FortiWeb External NICs (port1)
    var.deploy_fortiweb ? {
      "${var.deployment_prefix}-fwb-a-nic1-nsg-assoc" = {
        network_interface_id      = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-a-nic1"].id
        network_security_group_id = azurerm_network_security_group.network_security_group["${var.deployment_prefix}-nsg-fortiweb"].id
      }
      "${var.deployment_prefix}-fwb-b-nic1-nsg-assoc" = {
        network_interface_id      = azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-b-nic1"].id
        network_security_group_id = azurerm_network_security_group.network_security_group["${var.deployment_prefix}-nsg-fortiweb"].id
      }
    } : {}
  )

  #####################################################################
  # Public IPs
  #####################################################################

  public_ips = merge(
    # FortiGate Load Balancer Public IP (always created)
    {
      "${var.deployment_prefix}-fgt-pip" = {
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
        location            = azurerm_resource_group.resource_group[local.resource_group_name].location

        name              = var.fortigate_lb_public_ip_name != "" ? var.fortigate_lb_public_ip_name : "${var.deployment_prefix}-fgt-pip"
        allocation_method = "Static"
        sku               = "Standard"
        tags              = var.fortinet_tags
      }
    },
    # FortiGate Management Public IPs (conditional)
    var.enable_fortigate_mgmt_public_ips ? {
      "${var.deployment_prefix}-fgt-a-mgmt-pip" = {
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
        location            = azurerm_resource_group.resource_group[local.resource_group_name].location

        name              = var.fortigate_a_mgmt_public_ip_name != "" ? var.fortigate_a_mgmt_public_ip_name : "${var.deployment_prefix}-fgt-a-mgmt-pip"
        allocation_method = "Static"
        sku               = "Standard"
        tags              = var.fortinet_tags
      }
      "${var.deployment_prefix}-fgt-b-mgmt-pip" = {
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
        location            = azurerm_resource_group.resource_group[local.resource_group_name].location

        name              = var.fortigate_b_mgmt_public_ip_name != "" ? var.fortigate_b_mgmt_public_ip_name : "${var.deployment_prefix}-fgt-b-mgmt-pip"
        allocation_method = "Static"
        sku               = "Standard"
        tags              = var.fortinet_tags
      }
    } : {},
    # FortiWeb Load Balancer Public IP (always created)
    {
      "${var.deployment_prefix}-fwb-pip" = {
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
        location            = azurerm_resource_group.resource_group[local.resource_group_name].location

        name              = var.fortiweb_public_ip_name
        allocation_method = "Static"
        sku               = "Standard"
        tags              = var.fortinet_tags
      }
    }
  )
}
