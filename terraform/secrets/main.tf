resource "aws_kms_key" "secret_encryption" {
  description             = "KMS key for mllab secrets"
  enable_key_rotation     = true

  tags = {
    Environment = "mllab"
    Purpose     = "secrets-encryption"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/mllab-secrets"
  target_key_id = aws_kms_key.secret_encryption.key_id
}
