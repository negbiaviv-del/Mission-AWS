variable "ami_id" {
  description = "The AMI ID to use for the instances (e.g., Ubuntu 22.04)"
  type        = string
  default     = "ami-0c7217cdde317cfec" # וודא שזה ה-AMI הנכון לאזור שלך (us-east-1)
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the SSH key pair to use (e.g., avivPair-01)"
  type        = string
}

# משתני קישוריות (מגיעים ממודול ה-Networking)
variable "public_subnet_id" {
  description = "The ID of the public subnet for the Nginx/Frontend server"
  type        = string
}

variable "private_subnet_id" {
  description = "The ID of the private subnet for the Backend and Worker"
  type        = string
}

# משתני Security Groups
variable "nginx_sg_id" {
  description = "Security Group ID for the Nginx Frontend"
  type        = string
}

variable "backend_sg_id" {
  description = "Security Group ID for the Backend and Worker"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM profile to attach"
  type        = string
}
