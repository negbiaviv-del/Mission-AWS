# --- פלטים ממודול השרתים (EC2) ---
output "frontend_public_ip" {
  description = "The public IP of the Frontend (Nginx) server"
  value       = module.ec2_instances.nginx_public_ip
}

output "backend_private_ip" {
  description = "The private IP of the Backend server"
  value       = module.ec2_instances.backend_private_ip
}

output "worker_private_ip" {
  description = "The private IP of the Worker server"
  value       = module.ec2_instances.worker_private_ip
}

# --- פלטים ממודול בסיס הנתונים (RDS) ---
output "database_endpoint" {
  description = "The endpoint of the RDS database"
  value       = module.rds_postgresql.db_instance_endpoint
}

# --- פלטים ממודול מנתב העומסים (Load Balancer) ---
output "load_balancer_dns" {
  description = "The DNS address to access the application"
  value       = module.load_balancer.alb_dns_name
}

output "db_address" {
  description = "The address of the RDS instance"
  value       = module.rds_postgresql.db_instance_address 
}

output "db_user" {
  description = "The database username"
  value       = var.db_user
}

output "db_password" {
  description = "The database password"
  value       = var.master_db_password
  sensitive   = true
}