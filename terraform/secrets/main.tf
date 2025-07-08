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
    aws_ssm_parameter.parameters["mlflow_postgres"]
  ]
}


locals {
  parameters = {
    "mlflow-postgres-pw" = {
      description = "PW for the MLFlow postgres backend"
      value = var.mlflow-postgres-pw
    },
    "mlflow-admin-pw" = {
      description = "MLflow admin password"
      value = var.mlflow-admin-pw
    },
    "mlflow-admin-user" = {
      description = "MLflow admin username"
      value = var.mlflow-admin-user
    },
    "mlflow-flask-server-secret-key" = {
      description = "MLflow Flask server secret key"
      value = var.mlflow-flask-server-secret-key
    },
    "argocd-admin-pw" = {
      description = "ArgoCD admin password"
      value = var.argocd-admin-pw
    },
    "argocd-github-app-id" = {
      description = "ArgoCD GitHub App ID"
      value = var.argocd-github-app-id
    },
    "argocd-github-app-installation-id" = {
      description = "ArgoCD GitHub App installation ID"
      value = var.argocd-github-app-installation-id
    },
    "argocd-github-app-private-key" = {
      description = "ArgoCD GitHub App private key"
      value = var.argocd-github-app-private-key
    },
    "chromadb-token" = {
      description = "ChromaDB Token"
      value = var.chromadb-token
    }
  }
}

resource "aws_ssm_parameter" "parameters" {
  for_each = local.parameters

  # Generate path from key: "mlflow-postgres" → "/mllab/mlflow/postgres-pw"
  name = format("/mllab/%s/%s",
    split("-", each.key)[0],  # First part before hyphen (mlflow, argocd)
    join("-", slice(split("-", each.key), 1, length(split("-", each.key))))
  )
  description = each.value.description
  type        = "SecureString"
  value       = each.value.value
  key_id      = aws_kms_key.secret_encryption.key_id

  tags = {
    Environment = "mllab"
  }

  depends_on = [aws_kms_alias.secrets]
}
