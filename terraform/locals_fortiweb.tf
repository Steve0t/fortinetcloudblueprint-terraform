#####################################################################
# FortiWeb Locals (Active-Active HA Cluster)
# PAYG licensing only
#####################################################################

locals {
  #####################################################################
  # FortiWeb Network Interfaces (Port 1-2 for both FWB-A and FWB-B)
  #####################################################################

  network_interfaces_fortiweb = var.deploy_fortiweb == "yes" ? {
    # FortiWeb A - Port 1 (External)
    "${var.deployment_prefix}-fwb-a-nic1" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fwb-a-nic1"
      enable_ip_forwarding          = true
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet5_name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = var.subnet5_start_address
        public_ip_address_id          = null
        primary                       = true
      }]
    }

    # FortiWeb A - Port 2 (Internal)
    "${var.deployment_prefix}-fwb-a-nic2" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fwb-a-nic2"
      enable_ip_forwarding          = false
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].address_prefixes[0], tonumber(split(".", var.subnet6_start_address)[3]) + 1)
        public_ip_address_id          = null
        primary                       = true
      }]
    }

    # FortiWeb B - Port 1 (External)
    "${var.deployment_prefix}-fwb-b-nic1" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fwb-b-nic1"
      enable_ip_forwarding          = true
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet5_name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet5_name}"].address_prefixes[0], tonumber(split(".", var.subnet5_start_address)[3]) + 1)
        public_ip_address_id          = null
        primary                       = true
      }]
    }

    # FortiWeb B - Port 2 (Internal)
    "${var.deployment_prefix}-fwb-b-nic2" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-fwb-b-nic2"
      enable_ip_forwarding          = false
      enable_accelerated_networking = var.accelerated_networking

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].address_prefixes[0], tonumber(split(".", var.subnet6_start_address)[3]) + 2)
        public_ip_address_id          = null
        primary                       = true
      }]
    }
  } : {}

  #####################################################################
  # FortiWeb Virtual Machines
  #####################################################################

  virtual_machines_fortiweb = var.deploy_fortiweb == "yes" ? {
    "${var.deployment_prefix}-fwb-a" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-fwb-a"
      size = var.instance_type
      zone = var.availability_options == "Availability Zones" ? "1" : null

      admin_username                  = var.admin_username
      admin_password                  = var.admin_password
      disable_password_authentication = false

      custom_data = base64encode(templatefile("${path.module}/cloud-init/fortiweb.tpl", {
        var_admin_password          = var.admin_password
        var_ha_group_id             = var.fortiweb_ha_group_id
        var_ha_priority             = 1
        var_local_port2_ip          = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].address_prefixes[0], tonumber(split(".", var.subnet6_start_address)[3]) + 1)
        var_peer_port2_ip           = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].address_prefixes[0], tonumber(split(".", var.subnet6_start_address)[3]) + 2)
        var_subnet6_cidr            = split("/", var.subnet6_prefix)[1]
        var_vnet_address_prefix     = var.vnet_address_prefix
        var_subnet6_gateway         = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].address_prefixes[0], 1)
        var_workload_ip             = var.deploy_dvwa == "yes" ? var.subnet7_start_address : ""
        var_fortigate_ip            = var.subnet4_start_address
        var_admin_username          = var.admin_username
        var_fortiweb_public_ip      = azurerm_public_ip.public_ip["${var.deployment_prefix}-fwb-pip"].ip_address
        var_deployment_prefix       = var.deployment_prefix
        var_fortiweb_additional     = var.fortiweb_a_additional_custom_data
      }))

      network_interface_ids = [
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-a-nic1"].id,
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-a-nic2"].id
      ]

      source_image_reference = {
        publisher = "fortinet"
        offer     = "fortinet_fortiweb-vm_v5"
        sku       = var.fortiweb_image_sku
        version   = var.fortiweb_image_version
      }

      plan = {
        publisher = "fortinet"
        product   = "fortinet_fortiweb-vm_v5"
        name      = var.fortiweb_image_sku
      }

      os_disk = {
        name                 = "${var.deployment_prefix}-fwb-a-osdisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }

      data_disks = [{
        name                 = "${var.deployment_prefix}-fwb-a-datadisk"
        lun                  = 0
        caching              = "ReadWrite"
        create_option        = "Empty"
        disk_size_gb         = 30
        storage_account_type = "Standard_LRS"
      }]

      boot_diagnostics_enabled = var.fwb_serial_console == "yes"

      identity_type = "SystemAssigned"

      tags = var.fortinet_tags
    }

    "${var.deployment_prefix}-fwb-b" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-fwb-b"
      size = var.instance_type
      zone = var.availability_options == "Availability Zones" ? "2" : null

      admin_username                  = var.admin_username
      admin_password                  = var.admin_password
      disable_password_authentication = false

      custom_data = base64encode(templatefile("${path.module}/cloud-init/fortiweb.tpl", {
        var_admin_password          = var.admin_password
        var_ha_group_id             = var.fortiweb_ha_group_id
        var_ha_priority             = 2
        var_local_port2_ip          = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].address_prefixes[0], tonumber(split(".", var.subnet6_start_address)[3]) + 2)
        var_peer_port2_ip           = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].address_prefixes[0], tonumber(split(".", var.subnet6_start_address)[3]) + 1)
        var_subnet6_cidr            = split("/", var.subnet6_prefix)[1]
        var_vnet_address_prefix     = var.vnet_address_prefix
        var_subnet6_gateway         = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnet6_name}"].address_prefixes[0], 1)
        var_workload_ip             = var.deploy_dvwa == "yes" ? var.subnet7_start_address : ""
        var_fortigate_ip            = var.subnet4_start_address
        var_admin_username          = var.admin_username
        var_fortiweb_public_ip      = azurerm_public_ip.public_ip["${var.deployment_prefix}-fwb-pip"].ip_address
        var_deployment_prefix       = var.deployment_prefix
        var_fortiweb_additional     = var.fortiweb_b_additional_custom_data
      }))

      network_interface_ids = [
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-b-nic1"].id,
        azurerm_network_interface.network_interface["${var.deployment_prefix}-fwb-b-nic2"].id
      ]

      source_image_reference = {
        publisher = "fortinet"
        offer     = "fortinet_fortiweb-vm_v5"
        sku       = var.fortiweb_image_sku
        version   = var.fortiweb_image_version
      }

      plan = {
        publisher = "fortinet"
        product   = "fortinet_fortiweb-vm_v5"
        name      = var.fortiweb_image_sku
      }

      os_disk = {
        name                 = "${var.deployment_prefix}-fwb-b-osdisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }

      data_disks = [{
        name                 = "${var.deployment_prefix}-fwb-b-datadisk"
        lun                  = 0
        caching              = "ReadWrite"
        create_option        = "Empty"
        disk_size_gb         = 30
        storage_account_type = "Standard_LRS"
      }]

      boot_diagnostics_enabled = var.fwb_serial_console == "yes"

      identity_type = "SystemAssigned"

      tags = var.fortinet_tags
    }
  } : {}
}
