module "ec2" {
  source = "./ec2"

  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  volume_type   = var.volume_type
  volume_size   = var.volume_size
}
