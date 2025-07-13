# PostgreSQL RDS Terraform Configuration

AWS RDS PostgreSQL instance: PostgreSQL 16.4, db.t3.micro, 10GB GP3, single-AZ, private subnets.

## Usage

1. Configure `secret.auto.tfvars` with your values
2. `terraform init && terraform apply`

## Variables

Required (set in `secret.auto.tfvars`):
- `db_identifier`, `db_name`, `db_username`, `db_password`, `vpc_name`, `environment`

Optional (with defaults):
- `engine_version` (16.4), `instance_class` (db.t3.micro), `allocated_storage` (10)
- `max_allocated_storage` (20), `backup_retention_period` (7)
