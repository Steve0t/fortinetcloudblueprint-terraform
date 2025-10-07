resource "azurerm_lb_nat_rule" "lb_nat_rule" {
  for_each = local.lb_nat_rules

  name                           = each.value.name
  loadbalancer_id                = each.value.loadbalancer_id
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  floating_ip_enabled            = each.value.enable_floating_ip
  resource_group_name            = azurerm_lb.load_balancer["${var.deployment_prefix}-external-lb"].resource_group_name
}
