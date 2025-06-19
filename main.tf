  value       = var.mlflow-postgres-pw
  key_id      = aws_kms_key.secret_encryption.key_id

  tags = {
    Environment = "mllab"
  }

  depends_on = [aws_kms_alias.secrets]
}

resource "aws_ssm_parameter" "mlflow_admin_pw" {
  name        = "/mllab/mlflow/admin-pw"
  description = "MLflow admin password"
  type        = "SecureString"
  value       = var.mlflow-admin-pw
  key_id      = aws_kms_key.secret_encryption.key_id

  tags = {
    Environment = "mllab"
  }

  depends_on = [aws_kms_alias.secrets]
}

resource "aws_ssm_parameter" "mlflow_admin_user" {
  name        = "/mllab/mlflow/admin-user"
  description = "MLflow admin username"
  type        = "SecureString"
  value       = var.mlflow-admin-user
  key_id      = aws_kms_key.secret_encryption.key_id

  tags = {
    Environment = "mllab"
  }

  depends_on = [aws_kms_alias.secrets]
}

resource "aws_ssm_parameter" "mlflow_flask_server_secret_key" {
  name        = "/mllab/mlflow/flask-server-secret-key"
  description = "MLflow Flask server secret key"
  type        = "SecureString"
  value       = var.mlflow-flask-server-secret-key
  key_id      = aws_kms_key.secret_encryption.key_id

  tags = {
    Environment = "mllab"
  }

  depends_on = [aws_kms_alias.secrets]
}
