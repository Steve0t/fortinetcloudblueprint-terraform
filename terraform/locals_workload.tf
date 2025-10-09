#####################################################################
# Workload Locals (Multi-Container Demo Server)
# Replaces single DVWA with multiple vulnerable applications:
# - DVWA (port 1000)
# - OWASP Juice Shop (port 3000)
# - Swagger Petstore (port 4000)
# - Demo Web App / Bank (port 2000)
#####################################################################

locals {
  #####################################################################
  # Workload Network Interface
  #####################################################################

  network_interfaces_workload = var.deploy_dvwa ? {
    "${var.deployment_prefix}-workload-nic" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name                          = "${var.deployment_prefix}-workload-nic"
      enable_ip_forwarding          = false
      enable_accelerated_networking = false

      ip_configurations = [{
        name                          = "ipconfig1"
        subnet_id                     = azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["workload"].name}"].id
        private_ip_address_allocation = "Static"
        private_ip_address            = cidrhost(azurerm_subnet.subnet["${var.deployment_prefix}-${var.subnets["workload"].name}"].address_prefixes[0], tonumber(split(".", var.subnets["workload"].start_address)[3]) + 3)
        public_ip_address_id          = null
        primary                       = true
      }]
    }
  } : {}

  #####################################################################
  # Workload Virtual Machine
  #####################################################################

  virtual_machines_workload = var.deploy_dvwa ? {
    "${var.deployment_prefix}-workload" = {
      resource_group_name = azurerm_resource_group.resource_group[local.resource_group_name].name
      location            = azurerm_resource_group.resource_group[local.resource_group_name].location

      name = "${var.deployment_prefix}-workload"
      size = var.instance_type
      zone = var.availability_options == "Availability Zones" ? "1" : null

      admin_username                  = var.admin_username
      admin_password                  = var.admin_password
      disable_password_authentication = false

      custom_data = base64encode(templatefile("${path.module}/cloud-init/workload.tpl", {}))

      network_interface_ids = [
        azurerm_network_interface.network_interface["${var.deployment_prefix}-workload-nic"].id
      ]

      source_image_reference = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }

      plan = {
        publisher = null
        product   = null
        name      = null
      }

      os_disk = {
        name                 = "${var.deployment_prefix}-workload-osdisk"
        caching              = "ReadWrite"
        storage_account_type = local.standard_lrs
      }

      boot_diagnostics_enabled = var.workload_serial_console_enabled

      identity_type = "SystemAssigned"

      tags = var.fortinet_tags
    }
  } : {}
}
