output "db_instance_id" {
  description = "RDS instance identifier."
  value       = aws_db_instance.postgres.id
}

output "db_endpoint" {
  description = "RDS endpoint."
  value       = aws_db_instance.postgres.endpoint
}
