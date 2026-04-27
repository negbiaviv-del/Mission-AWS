output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main_vpc.id
}

output "subnet_id" {
  description = "The ID of the Subnet"
  value       = aws_subnet.main_subnet.id
}

output "subnet2_id" {
  description = "The ID of the second Subnet"
  value       = aws_subnet.second_subnet.id
}