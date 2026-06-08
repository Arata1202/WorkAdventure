module "vm" {
  source = "./vm"

  location              = var.location
  resource_group_name   = var.resource_group_name
  vnet_address_space    = var.vnet_address_space
  subnet_address_prefix = var.subnet_address_prefix
  admin_username        = var.admin_username
  ssh_public_key        = var.ssh_public_key
  vm_size               = var.vm_size
  os_disk_type          = var.os_disk_type
  os_disk_size_gb       = var.os_disk_size_gb
  image_publisher       = var.image_publisher
  image_offer           = var.image_offer
  image_sku             = var.image_sku
  image_version         = var.image_version
}
