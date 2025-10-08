resource "azurerm_network_interface" "network_interface" {
  for_each = local.network_interfaces

  name                           = each.value.name
  location                       = each.value.location
  resource_group_name            = each.value.resource_group_name
  ip_forwarding_enabled          = each.value.enable_ip_forwarding
  accelerated_networking_enabled = each.value.enable_accelerated_networking

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations
    content {
      name                          = ip_configuration.value.name
      subnet_id                     = ip_configuration.value.subnet_id
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
      private_ip_address            = ip_configuration.value.private_ip_address
      public_ip_address_id          = ip_configuration.value.public_ip_address_id
      primary                       = ip_configuration.value.primary
    }
  }

  depends_on = [
    azurerm_subnet.subnet,
    azurerm_public_ip.public_ip
  ]
}

output "network_interfaces" {
  value = var.enable_output ? azurerm_network_interface.network_interface[*] : null
}
