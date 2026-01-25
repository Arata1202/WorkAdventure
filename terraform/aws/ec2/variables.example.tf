variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "volume_type" {
  type = string
}

variable "volume_size" {
  type = number
}

variable "volume_encrypted" {
  type = bool
}

variable "volume_kms_key_id" {
  type = string
}
