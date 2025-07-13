# RDS PostgreSQL Outputs
output "postgres_endpoint" {
  description = "PostgreSQL RDS instance endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "postgres_port" {
  description = "PostgreSQL RDS instance port"
  value       = aws_db_instance.postgres.port
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}

output "postgres_username" {
  description = "PostgreSQL master username"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

output "postgres_identifier" {
  description = "PostgreSQL RDS instance identifier"
  value       = aws_db_instance.postgres.identifier
}

output "postgres_arn" {
  description = "PostgreSQL RDS instance ARN"
  value       = aws_db_instance.postgres.arn
}

output "postgres_security_group_id" {
  description = "Security group ID for PostgreSQL RDS"
  value       = aws_security_group.postgres_sg.id
}