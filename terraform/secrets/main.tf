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
  depends_on = [aws_ssm_parameter.mlflow-postgres]
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
}


