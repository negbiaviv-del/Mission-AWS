output "db_endpoint" {
  description = "The connection endpoint for the PostgreSQL database"
  value       = aws_db_instance.postgres.endpoint
}