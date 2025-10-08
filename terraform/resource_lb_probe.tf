resource "azurerm_lb_probe" "lb_probe" {
  for_each = local.lb_probes

  name                = each.value.name
  loadbalancer_id     = each.value.loadbalancer_id
  protocol            = each.value.protocol
  port                = each.value.port
  interval_in_seconds = each.value.interval
  number_of_probes    = each.value.probe_threshold
}
