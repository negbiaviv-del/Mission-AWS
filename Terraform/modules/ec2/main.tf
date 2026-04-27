resource "aws_instance" "web_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id # שימוש במשתנה שקיבלנו מהרשת

  tags = {
    Name = "Mission-Web-Server"
  }
}