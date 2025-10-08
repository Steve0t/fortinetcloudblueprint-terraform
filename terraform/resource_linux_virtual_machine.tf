resource "azurerm_linux_virtual_machine" "linux_virtual_machine" {
  for_each = local.virtual_machines

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  size                = each.value.size
  zone                = each.value.zone

  admin_username                  = each.value.admin_username
  admin_password                  = each.value.admin_password
  disable_password_authentication = each.value.disable_password_authentication

  custom_data = each.value.custom_data

  network_interface_ids = each.value.network_interface_ids

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  dynamic "plan" {
    for_each = each.value.plan.publisher != null ? [1] : []
    content {
      publisher = each.value.plan.publisher
      product   = each.value.plan.product
      name      = each.value.plan.name
    }
  }

  os_disk {
    name                 = each.value.os_disk.name
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
  }

  boot_diagnostics {
    storage_account_uri = each.value.boot_diagnostics_enabled ? null : null
  }

  identity {
    type = each.value.identity_type
  }

  tags = each.value.tags

  depends_on = [
    azurerm_network_interface.network_interface
  ]
}

