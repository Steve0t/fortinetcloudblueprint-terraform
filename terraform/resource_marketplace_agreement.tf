resource "null_resource" "marketplace_agreement_fortigate" {
  provisioner "local-exec" {
    command = "az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan ${var.fortigate_image_sku}"
  }

  triggers = {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = var.fortigate_image_sku
  }
}

resource "null_resource" "marketplace_agreement_fortiweb" {
  count = var.deploy_dvwa == "yes" ? 0 : 0  # TODO: Enable when FortiWeb is implemented

  provisioner "local-exec" {
    command = "az vm image terms accept --publisher fortinet --offer fortinet_fortiweb-vm_v5 --plan ${var.fortiweb_image_sku}"
  }

  triggers = {
    publisher = "fortinet"
    offer     = "fortinet_fortiweb-vm_v5"
    sku       = var.fortiweb_image_sku
  }
}
