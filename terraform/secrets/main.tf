resource "aws_kms_key" "secret_encryption" {
  description             = "KMS key for mllab secrets"
  enable_key_rotation     = true

  tags = {
    Environment = "mllab"
    Purpose     = "secret-encryption"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/mllab-secrets"
  target_key_id = aws_kms_key.secret_encryption.key_id
}

# If tfvars doesn't exist, decrypt the file using SOPS
resource "null_resource" "decrypt_secrets" {
  count = fileexists("${path.module}/secret.auto.tfvars") ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      sops -d "${path.module}/secrets.enc.yaml" > "${path.module}/secret.auto.tfvars"
      echo "Decrypted secrets.enc.yaml to secret.auto.tfvars"
    EOT
  }

  depends_on = [aws_kms_alias.secrets]
}

resource "terraform_data" "encrypt_secrets" {
  triggers_replace = [
    filemd5("${path.module}/secret.auto.tfvars")
  ]
  
  provisioner "local-exec" {
    command = <<-EOT
      sops -e "${path.module}/secret.auto.tfvars" > "${path.module}/secrets.enc.yaml"
      echo "Encrypted secret.auto.tfvars into secrets.enc.yaml"
    EOT
  }
  # just to ensure it doesn't overwrite stuff
  depends_on = [
    aws_ssm_parameter.mlflow-postgres
  ]
}


resource "aws_ssm_parameter" "mlflow-postgres" {
  name        = "/mllab/mlflow/postgres-pw"
  description = "PW for the MLFlow postgres backend"
  type        = "SecureString"
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

resource "aws_ssm_parameter" "argocd_admin_pw" {
  name        = "/mllab/argocd/admin-pw"
  description = "ArgoCD admin password"
  type        = "SecureString"
  value       = var.argocd-admin-pw
  key_id      = aws_kms_key.secret_encryption.key_id

  tags = {
    Environment = "mllab"
  }

  depends_on = [aws_kms_alias.secrets]
}

# resource "aws_ssm_parameter" "argocd_github_app_repo" {
#   name        = "/mllab/argocd/github-app-repo"
#   description = "ArgoCD GitHub App repository configuration"
#   type        = "SecureString"
#   value       = var.argocd-github-app-repo
#   key_id      = aws_kms_key.secret_encryption.key_id
#
#   tags = {
#     Environment = "mllab"
#   }
#
#   depends_on = [aws_kms_alias.secrets]
# }

