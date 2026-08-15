# 1. שרת Frontend (Nginx) - ללא IAM בדרך כלל
resource "aws_instance" "nginx_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.nginx_sg_id]

  tags = { Name = "Mission-Nginx-Frontend" }
}

# 2. שרת Backend - משתמש במשתנה
resource "aws_instance" "backend_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.backend_sg_id]

  iam_instance_profile = var.iam_instance_profile_name

  tags = { Name = "Mission-App-Backend" }
}

# 3. שרת Worker/Service - משתמש במשתנה
resource "aws_instance" "worker_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.backend_sg_id]

  iam_instance_profile = var.iam_instance_profile_name

  tags = { Name = "Mission-Worker-Service" }
}