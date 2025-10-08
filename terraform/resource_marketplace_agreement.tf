resource "azurerm_marketplace_agreement" "marketplace_agreement" {
  for_each = local.marketplace_agreements

  publisher = each.value.publisher
  offer     = each.value.offer
  plan      = each.value.plan
}
