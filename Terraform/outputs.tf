output "load_balancer_url" {
  description = "The URL of the website"
  value       = module.load_balancer.lb_dns_name
}

output "database_endpoint" {
  description = "The connection string for the DB"
  value       = module.rds_postgresql.db_endpoint
}

output "s3_bucket_name" {
  value = module.my_s3_bucket.bucket_name
}

output "instance_public_ip" {
  description = "Public IP of the frontend server"
  value       = aws_instance.frontend_server.public_ip
}