variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "iam_role" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "subnet2_cidr" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "sns_topic_name" {
  type = string
}

variable "secret_name" {
  type = string
}

variable "secret_description" {
  type        = string
  description = "The description for the RDS secret"
}

variable "my_ip" {
  description = "Your public IP address"
  type        = string
}