# PostgreSQL RDS Terraform Configuration

This Terraform configuration creates a simple AWS RDS PostgreSQL instance with the following specifications:

## Configuration Details

- **Engine**: PostgreSQL 16.4 (latest stable version)
- **Instance Class**: db.t3.micro (smallest available instance)
- **Storage**: 10GB GP3 storage with encryption enabled
- **Deployment**: Single-AZ deployment
- **Network**: Deployed in private subnets with VPC security group

## Files Structure

- `postgres.tf` - Main RDS instance configuration
- `data.tf` - Data sources for VPC and subnet information
- `variables.tf` - Configurable variables
- `outputs.tf` - Output values for connection information
- `providers.tf` - AWS provider configuration
- `versions.tf` - Terraform and provider version constraints

## Usage

1. Ensure the VPC infrastructure is already deployed
2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Plan the deployment:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `db_identifier` | RDS instance identifier | `mllab-postgres` |
| `db_name` | Database name | `mllab` |
| `db_username` | Master username | `postgres` |
| `db_password` | Master password | `changeme123!` |
| `engine_version` | PostgreSQL version | `16.4` |
| `instance_class` | Instance type | `db.t3.micro` |
| `allocated_storage` | Storage size in GB | `10` |
| `max_allocated_storage` | Max auto-scaling storage | `20` |
| `backup_retention_period` | Backup retention days | `7` |
| `vpc_name` | VPC name to deploy in | `mllab-vpc` |
| `environment` | Environment tag | `development` |

## Outputs

- `postgres_endpoint` - Database endpoint
- `postgres_port` - Database port
- `postgres_database_name` - Database name
- `postgres_username` - Master username (sensitive)
- `postgres_identifier` - RDS instance identifier
- `postgres_arn` - RDS instance ARN
- `postgres_security_group_id` - Security group ID

## Security

- Database is deployed in private subnets
- Security group allows access only from VPC CIDR block
- Storage encryption is enabled
- Database is not publicly accessible

## Important Notes

- **Password Security**: The default password should be changed in production. Consider using AWS Secrets Manager for better security.
- **Backup**: 7-day backup retention is configured with automated backups.
- **Monitoring**: Performance Insights is disabled to keep costs minimal.
- **Deletion Protection**: Disabled for development environment. Enable for production.

## Connection Example

After deployment, you can connect to the database using:

```bash
psql -h <postgres_endpoint> -p 5432 -U postgres -d mllab
```

Replace `<postgres_endpoint>` with the actual endpoint from the terraform output.