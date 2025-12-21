resource "aws_eip" "workadventure_eip" {
  domain = "vpc"

  tags = {
    Name = "workadventure_eip"
  }
}

resource "aws_eip_association" "workadventure_eip_association" {
  instance_id   = aws_instance.workadventure_server.id
  allocation_id = aws_eip.workadventure_eip.id
}
