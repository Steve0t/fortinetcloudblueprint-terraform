#####################################################################
# Azure Marketplace Agreements
#
# Defines marketplace terms acceptance for Fortinet products.
# Azure requires explicit acceptance of marketplace terms before
# deploying VMs from Azure Marketplace images.
#
# Pattern: Conditional merge for optional products
#####################################################################

locals {
  #####################################################################
  # Marketplace Agreements
  #####################################################################

  marketplace_agreements = merge(
    # FortiGate marketplace agreement (always required)
    {
      "fortigate" = {
        publisher = local.fortinet_publisher
        offer     = local.fortigate_offer
        plan      = var.fortigate_image_sku
      }
    },

    # FortiWeb marketplace agreement (conditional: var.deploy_fortiweb)
    var.deploy_fortiweb ? {
      "fortiweb" = {
        publisher = local.fortinet_publisher
        offer     = local.fortiweb_offer
        plan      = var.fortiweb_image_sku
      }
    } : {}
  )
}
