variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "A list of public subnet IDs for the ALB"
  type        = list(string)
}

variable "nginx_instance_id" {
  description = "The EC2 instance ID of the Nginx frontend server to attach to the ALB"
  type        = string
}