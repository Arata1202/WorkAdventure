resource "aws_instance" "workadventure_server" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.workadventure_iam_instance_profile.name
  vpc_security_group_ids = [aws_security_group.workadventure_sg.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    encrypted             = var.volume_encrypted
    kms_key_id            = var.volume_kms_key_id
    delete_on_termination = false
  }

  tags = {
    Name = "workadventure_server"
  }
}
