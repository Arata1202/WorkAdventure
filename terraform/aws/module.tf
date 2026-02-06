module "ec2" {
  source = "./ec2"

  ami               = var.ami
  instance_type     = var.instance_type
  volume_type       = var.volume_type
  volume_size       = var.volume_size
  volume_encrypted  = var.volume_encrypted
  volume_kms_key_id = var.volume_kms_key_id
}
