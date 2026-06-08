variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_address_space" {
  type = string
}

variable "subnet_address_prefix" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "os_disk_type" {
  type = string
}

variable "os_disk_size_gb" {
  type = number
}

variable "image_publisher" {
  type = string
}

variable "image_offer" {
  type = string
}

variable "image_sku" {
  type = string
}

variable "image_version" {
  type = string
}
