resource "azurerm_route_table" "route_table" {
  for_each = local.route_tables

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = each.value.tags

  depends_on = [azurerm_resource_group.resource_group]
}
