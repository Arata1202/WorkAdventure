resource "aws_instance" "workadventure_server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.workadventure_sg.id]

  root_block_device {
    volume_type = var.volume_type
    volume_size = var.volume_size
    encrypted   = var.volume_encrypted
    kms_key_id  = var.volume_kms_key_id
    delete_on_termination = false
  }

  tags = {
    Name = "workadventure_server"
  }
}
