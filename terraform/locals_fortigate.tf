locals {
  #####################################################################
  # FortiGate Network Interfaces (Port 1-4 for both FGT-A and FGT-B)
  #####################################################################

  network_interfaces_fortigate = {
    # FortiGate A - Port 1 (External)
    "${var.deployment_prefix}-fgt-a-nic1" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fgt-a-nic1"
      enable_ip_forwarding          = false
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_external"].name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_external"].name}"].address_prefixes[0], tonumber(split(".", var.subnets["fortigate_external"].start_address)[3]) + 1)
        public_ip_address_id          = null
        primary                       = true
      }]
    }
    # FortiGate A - Port 2 (Internal)
    "${var.deployment_prefix}-fgt-a-nic2" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fgt-a-nic2"
      enable_ip_forwarding          = true
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}"].address_prefixes[0], tonumber(split(".", var.subnets["fortigate_internal"].start_address)[3]) + 1)
        public_ip_address_id          = null
        primary                       = true
      }]
    }
    # FortiGate A - Port 3 (HA Sync)
    "${var.deployment_prefix}-fgt-a-nic3" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fgt-a-nic3"
      enable_ip_forwarding          = false
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_ha"].name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_ha"].name}"].address_prefixes[0], tonumber(split(".", var.subnets["fortigate_ha"].start_address)[3]) + 1)
        public_ip_address_id          = null
        primary                       = true
      }]
    }
    # FortiGate A - Port 4 (Management)
    "${var.deployment_prefix}-fgt-a-nic4" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fgt-a-nic4"
      enable_ip_forwarding          = false
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_management"].name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_management"].name}"].address_prefixes[0], tonumber(split(".", var.subnets["fortigate_management"].start_address)[3]) + 1)
        public_ip_address_id          = var.enable_fortigate_mgmt_public_ips ? azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-a-mgmt-pip"].id : null
        primary                       = true
      }]
    }
    # FortiGate B - Port 1 (External)
    "${var.deployment_prefix}-fgt-b-nic1" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fgt-b-nic1"
      enable_ip_forwarding          = false
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_external"].name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_external"].name}"].address_prefixes[0], tonumber(split(".", var.subnets["fortigate_external"].start_address)[3]) + 2)
        public_ip_address_id          = null
        primary                       = true
      }]
    }
    # FortiGate B - Port 2 (Internal)
    "${var.deployment_prefix}-fgt-b-nic2" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fgt-b-nic2"
      enable_ip_forwarding          = true
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}"].address_prefixes[0], tonumber(split(".", var.subnets["fortigate_internal"].start_address)[3]) + 2)
        public_ip_address_id          = null
        primary                       = true
      }]
    }
    # FortiGate B - Port 3 (HA Sync)
    "${var.deployment_prefix}-fgt-b-nic3" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fgt-b-nic3"
      enable_ip_forwarding          = false
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_ha"].name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_ha"].name}"].address_prefixes[0], tonumber(split(".", var.subnets["fortigate_ha"].start_address)[3]) + 2)
        public_ip_address_id          = null
        primary                       = true
      }]
    }
    # FortiGate B - Port 4 (Management)
    "${var.deployment_prefix}-fgt-b-nic4" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fgt-b-nic4"
      enable_ip_forwarding          = false
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_management"].name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_management"].name}"].address_prefixes[0], tonumber(split(".", var.subnets["fortigate_management"].start_address)[3]) + 2)
        public_ip_address_id          = var.enable_fortigate_mgmt_public_ips ? azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-b-mgmt-pip"].id : null
        primary                       = true
      }]
    }
  }

  #####################################################################
  # FortiGate Virtual Machines (FGT-A and FGT-B)
  #####################################################################

  virtual_machines_fortigate = {
    "${var.deployment_prefix}-fgt-a" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-fgt-a"
      size = var.instance_type
      zone = var.availability_options == "Availability Zones" ? local.availability_zone_1 : null

      admin_username                  = var.admin_username
      admin_password                  = var.admin_password
      disable_password_authentication = false

      custom_data = base64encode(templatefile("${path.module}/cloud-init/fortigate.tpl", {
        var_hostname                    = "${var.deployment_prefix}-fgt-a"
        var_vnet_address_prefix         = var.vnet_address_prefix
        var_subnet1_name                = var.subnets["fortigate_external"].name
        var_subnet2_name                = var.subnets["fortigate_internal"].name
        var_subnet3_name                = var.subnets["fortigate_ha"].name
        var_subnet4_name                = var.subnets["fortigate_management"].name
        var_sn1_gateway                 = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_external"].name}"].address_prefixes[0], 1)
        var_sn2_gateway                 = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}"].address_prefixes[0], 1)
        var_sn4_gateway                 = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_management"].name}"].address_prefixes[0], 1)
        var_port1_ip                    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic1"].private_ip_address
        var_port1_netmask               = cidrnetmask(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_external"].name}"].address_prefixes[0])
        var_port2_ip                    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic2"].private_ip_address
        var_port2_netmask               = cidrnetmask(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}"].address_prefixes[0])
        var_port3_ip                    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic3"].private_ip_address
        var_port3_netmask               = cidrnetmask(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_ha"].name}"].address_prefixes[0])
        var_port4_ip                    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic4"].private_ip_address
        var_port4_netmask               = cidrnetmask(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_management"].name}"].address_prefixes[0])
        var_ha_priority                 = 255
        var_ha_peer_ip                  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic3"].private_ip_address
        var_fgt_external_ipaddress      = azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-pip"].ip_address
        var_dvwa_vm_ip                  = var.deploy_dvwa ? azurerm_network_interface.network_interface["${var.deployment_prefix}-workload-nic"].private_ip_address : ""
        var_deploy_dvwa                 = var.deploy_dvwa
        var_fortimanager                = var.fortimanager
        var_fortimanager_ip             = var.fortimanager_ip
        var_fortimanager_serial         = var.fortimanager_serial
        var_fortigate_license_byol      = var.fortigate_license_byol_a
        var_fortigate_license_flexvm    = var.fortigate_license_flexvm_a
        var_fortigate_additional_config = var.fortigate_additional_custom_data
        var_azure_metadata_ip           = var.azure_metadata_ip
        var_admin_password              = var.admin_password
      }))

      network_interface_ids = [
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic1"].id,
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic2"].id,
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic3"].id,
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic4"].id
      ]

      source_image_reference = {
        publisher = local.fortinet_publisher
        offer     = local.fortigate_offer
        sku       = var.fortigate_image_sku
        version   = var.fortigate_image_version
      }

      plan = {
        publisher = local.fortinet_publisher
        product   = local.fortigate_product
        name      = var.fortigate_image_sku
      }

      os_disk = {
        name                 = "${var.deployment_prefix}-fgt-a-osdisk"
        caching              = "ReadWrite"
        storage_account_type = local.standard_lrs
      }

      boot_diagnostics_enabled = var.fortigate_serial_console_enabled

      identity_type = "SystemAssigned"

      tags = var.fortinet_tags
    }
    "${var.deployment_prefix}-fgt-b" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-fgt-b"
      size = var.instance_type
      zone = var.availability_options == "Availability Zones" ? local.availability_zone_2 : null

      admin_username                  = var.admin_username
      admin_password                  = var.admin_password
      disable_password_authentication = false

      custom_data = base64encode(templatefile("${path.module}/cloud-init/fortigate.tpl", {
        var_hostname                    = "${var.deployment_prefix}-fgt-b"
        var_vnet_address_prefix         = var.vnet_address_prefix
        var_subnet1_name                = var.subnets["fortigate_external"].name
        var_subnet2_name                = var.subnets["fortigate_internal"].name
        var_subnet3_name                = var.subnets["fortigate_ha"].name
        var_subnet4_name                = var.subnets["fortigate_management"].name
        var_sn1_gateway                 = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_external"].name}"].address_prefixes[0], 1)
        var_sn2_gateway                 = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}"].address_prefixes[0], 1)
        var_sn4_gateway                 = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_management"].name}"].address_prefixes[0], 1)
        var_port1_ip                    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic1"].private_ip_address
        var_port1_netmask               = cidrnetmask(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_external"].name}"].address_prefixes[0])
        var_port2_ip                    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic2"].private_ip_address
        var_port2_netmask               = cidrnetmask(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_internal"].name}"].address_prefixes[0])
        var_port3_ip                    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic3"].private_ip_address
        var_port3_netmask               = cidrnetmask(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_ha"].name}"].address_prefixes[0])
        var_port4_ip                    = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic4"].private_ip_address
        var_port4_netmask               = cidrnetmask(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["fortigate_management"].name}"].address_prefixes[0])
        var_ha_priority                 = 1
        var_ha_peer_ip                  = azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-a-nic3"].private_ip_address
        var_fgt_external_ipaddress      = azurerm_public_ip.public_ip["${var.deployment_prefix}-fgt-pip"].ip_address
        var_dvwa_vm_ip                  = var.deploy_dvwa ? azurerm_network_interface.network_interface["${var.deployment_prefix}-workload-nic"].private_ip_address : ""
        var_deploy_dvwa                 = var.deploy_dvwa
        var_fortimanager                = var.fortimanager
        var_fortimanager_ip             = var.fortimanager_ip
        var_fortimanager_serial         = var.fortimanager_serial
        var_fortigate_license_byol      = var.fortigate_license_byol_b
        var_fortigate_license_flexvm    = var.fortigate_license_flexvm_b
        var_fortigate_additional_config = var.fortigate_additional_custom_data
        var_azure_metadata_ip           = var.azure_metadata_ip
        var_admin_password              = var.admin_password
      }))

      network_interface_ids = [
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic1"].id,
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic2"].id,
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic3"].id,
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fgt-b-nic4"].id
      ]

      source_image_reference = {
        publisher = local.fortinet_publisher
        offer     = local.fortigate_offer
        sku       = var.fortigate_image_sku
        version   = var.fortigate_image_version
      }

      plan = {
        publisher = local.fortinet_publisher
        product   = local.fortigate_product
        name      = var.fortigate_image_sku
      }

      os_disk = {
        name                 = "${var.deployment_prefix}-fgt-b-osdisk"
        caching              = "ReadWrite"
        storage_account_type = local.standard_lrs
      }

      boot_diagnostics_enabled = var.fortigate_serial_console_enabled

      identity_type = "SystemAssigned"

      tags = var.fortinet_tags
    }
  }
}
