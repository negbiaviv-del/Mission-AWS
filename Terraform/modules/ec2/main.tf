resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [var.web_sg_id] # השורה שחיברת

  tags = {
    Name = "Mission-Web-Server"
  }
}