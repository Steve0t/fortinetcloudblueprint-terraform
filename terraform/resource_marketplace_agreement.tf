resource "null_resource" "marketplace_agreement_fortigate" {
  provisioner "local-exec" {
    command = "az vm image terms accept --publisher ${local.fortinet_publisher} --offer ${local.fortigate_offer} --plan ${var.fortigate_image_sku}"
  }

  triggers = {
    publisher = local.fortinet_publisher
    offer     = local.fortigate_offer
    sku       = var.fortigate_image_sku
  }
}

resource "null_resource" "marketplace_agreement_fortiweb" {
  count = var.deploy_dvwa ? 0 : 0 # TODO: Enable when FortiWeb is implemented

  provisioner "local-exec" {
    command = "az vm image terms accept --publisher ${local.fortinet_publisher} --offer ${local.fortiweb_offer} --plan ${var.fortiweb_image_sku}"
  }

  triggers = {
    publisher = local.fortinet_publisher
    offer     = local.fortiweb_offer
    sku       = var.fortiweb_image_sku
  }
}
