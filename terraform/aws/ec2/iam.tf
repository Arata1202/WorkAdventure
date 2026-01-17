resource "aws_iam_role" "workadventure_ec2_role" {
  name = "workadventure_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "workadventure_instance_profile" {
  name = "workadventure_instance_profile"
  role = aws_iam_role.workadventure_ec2_role.name
}
