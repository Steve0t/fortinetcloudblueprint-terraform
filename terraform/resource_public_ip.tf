resource "azurerm_public_ip" "public_ip" {
  for_each = local.public_ips

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = each.value.allocation_method
  sku                 = each.value.sku
  tags                = each.value.tags

  depends_on = [azurerm_resource_group.resource_group]
}

output "public_ips" {
  value = var.enable_output ? azurerm_public_ip.public_ip[*] : null
}
