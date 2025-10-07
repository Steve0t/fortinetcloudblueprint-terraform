resource "azurerm_lb_rule" "lb_rule" {
  for_each = local.lb_rules

  name                           = each.value.name
  loadbalancer_id                = each.value.loadbalancer_id
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  backend_address_pool_ids       = each.value.backend_address_pool_ids
  probe_id                       = each.value.probe_id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  floating_ip_enabled            = each.value.enable_floating_ip
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
}
