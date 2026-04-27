variable "secret_name" {
  description = "The name of the secret in AWS Secrets Manager"
  type        = string
  default     = "mission-db-password-aviv"
}

variable "secret_description" {
  description = "Description of what this secret is for"
  type        = string
  default     = "Database password for the mission project"
}