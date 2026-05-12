output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_id" {
  value = aws_subnet.main.id
}

output "subnet2_id" {
  value = aws_subnet.second.id
}

output "web_sg_id" {
  value = aws_security_group.web_sg.id
}