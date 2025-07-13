output "postgres_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "postgres_port" {
  value = aws_db_instance.postgres.port
}

output "postgres_username" {
  value     = aws_db_instance.postgres.username
  sensitive = true
}

output "postgres_identifier" {
  value = aws_db_instance.postgres.identifier
}

output "postgres_arn" {
  value = aws_db_instance.postgres.arn
}

output "postgres_security_group_id" {
  value = aws_security_group.postgres_sg.id
}
