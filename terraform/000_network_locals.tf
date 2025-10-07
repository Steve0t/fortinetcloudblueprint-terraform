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
    "${var.deployment_prefix}-${var.subnet1_name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnet1_name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnet1_prefix]
    }
    "${var.deployment_prefix}-${var.subnet2_name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnet2_name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnet2_prefix]
    }
    "${var.deployment_prefix}-${var.subnet3_name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnet3_name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnet3_prefix]
    }
    "${var.deployment_prefix}-${var.subnet4_name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnet4_name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnet4_prefix]
    }
    "${var.deployment_prefix}-${var.subnet5_name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnet5_name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnet5_prefix]
    }
    "${var.deployment_prefix}-${var.subnet6_name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnet6_name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnet6_prefix]
    }
    "${var.deployment_prefix}-${var.subnet7_name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

      name                 = var.subnet7_name
      virtual_network_name = azurerm_virtual_network.virtual_network[local.vnet_name].name
      address_prefixes     = [var.subnet7_prefix]
    }
  }

  #####################################################################
  # Route Tables
  #####################################################################

  route_tables = {
    "${var.deployment_prefix}-rt-${var.subnet7_name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-rt-${var.subnet7_name}"
      tags = {
      }
    }
    "${var.deployment_prefix}-rt-${var.subnet5_name}" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-rt-${var.subnet5_name}"
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
      "${var.deployment_prefix}-route-default-${var.subnet7_name}" = {
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

        name                   = "toDefault"
        route_table_name       = "${var.deployment_prefix}-rt-${var.subnet7_name}"
        address_prefix         = "0.0.0.0/0"
        next_hop_type          = "VirtualAppliance"
        next_hop_in_ip_address = azurerm_lb.load_balancer["${var.deployment_prefix}-internal-lb"].frontend_ip_configuration[0].private_ip_address
      }
    },
    var.on_prem_range != "" ? {
      "${var.deployment_prefix}-route-onprem-${var.subnet5_name}" = {
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name

        name                   = "toOnPrem"
        route_table_name       = "${var.deployment_prefix}-rt-${var.subnet5_name}"
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
    "${var.deployment_prefix}-${var.subnet7_name}-rt-association" = {
      subnet_id      = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet7_name}"].id
      route_table_id = azurerm_route_table.route_table["${var.deployment_prefix}-rt-${var.subnet7_name}"].id
    }
    "${var.deployment_prefix}-${var.subnet5_name}-rt-association" = {
      subnet_id      = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet5_name}"].id
      route_table_id = azurerm_route_table.route_table["${var.deployment_prefix}-rt-${var.subnet5_name}"].id
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
          destination_port_range     = "443"
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
          destination_port_range     = "22"
          source_address_prefix      = local.detected_public_ip
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

        name              = var.public_ip1_name != "" ? var.public_ip1_name : "${var.deployment_prefix}-fgt-pip"
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

        name              = var.public_ip2_name != "" ? var.public_ip2_name : "${var.deployment_prefix}-fgt-a-mgmt-pip"
        allocation_method = "Static"
        sku               = "Standard"
        tags              = var.fortinet_tags
      }
      "${var.deployment_prefix}-fgt-b-mgmt-pip" = {
        resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
        location            = azurerm_resource_group.resource_group[local.resource_group_name].location

        name              = var.public_ip3_name != "" ? var.public_ip3_name : "${var.deployment_prefix}-fgt-b-mgmt-pip"
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
