resource "azurerm_linux_virtual_machine" "workadventure_vm" {
  name                            = "workadventure_vm"
  computer_name                   = "workadventurevm"
  location                        = azurerm_resource_group.workadventure_rg.location
  resource_group_name             = azurerm_resource_group.workadventure_rg.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.workadventure_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
}
