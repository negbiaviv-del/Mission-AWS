variable "instance_type" {
  default = "t3.micro"
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI"
  default     = "ami-0c7217cdde317cfec" # AMI של Ubuntu באזור us-east-1. וודא שזה מתאים לאזור שלך.
}

variable "subnet_id" {
  description = "The subnet ID where the instance will be created"
  type        = string
}