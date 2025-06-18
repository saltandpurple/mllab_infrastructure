# MLLab Secrets Management

This directory manages secrets for the MLLab cluster using AWS Parameter Store with KMS encryption.

## Architecture

1. **You only edit** `secret.auto.tfvars` (gitignored, plaintext)
2. **Terraform automatically decrypts** from `secrets.enc.yaml` if tfvars doesn't exist (using a dedicated KMS key)
3. **Terraform automatically encrypts** tfvars → `secrets.enc.yaml` after deployment
4. **Parameter Store encrypts** them using the same KMS key
5. **External Secrets Operator** reads from Parameter Store and creates Kubernetes secrets
6. **Applications consume** standard Kubernetes secrets

## Prerequisites

Install required tools:
```bash
brew install sops yq
```

## Workflow

### 1. Edit & apply secrets

1. Run `terraform plan` - Terraform automatically decrypts `secrets.enc.yaml` → `secret.auto.tfvars`
2. Edit `secret.auto.tfvars` with changed/new values -> add variable-refs for ssm param store as well, obviously
3. Run `terraform apply` - Terraform deploys the secrets to the param store and encrypts the tfvars-file

The secret is now encrypted and stored in AWS Parameter Store.

## 2. Create ExternalSecret manifest

This is required so the ESO picks up the secret.

Add to `../argocd/infrastructure/external-secrets/manifests/`:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: myapp-secrets
  namespace: myapp
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-parameter-store
    kind: SecretStore
  target:
    name: myapp-secrets
    creationPolicy: Owner
  data:
  - secretKey: api-key
    remoteRef:
      key: /mllab/myapp/api-key
```

### 3. Commit and let ArgoCD sync

ArgoCD will deploy the ExternalSecret, ESO will read from Parameter Store, and create the Kubernetes secret.

## Path Convention

All secrets use the path prefix `/mllab/` followed by:
- `/mllab/{service}/{secret-name}` - Service-specific secrets
- `/mllab/shared/{secret-name}` - Shared secrets

## Security Model

- **Encrypted in git**: Secrets are encrypted with SOPS using KMS key and safe to commit
- **Local decryption**: `secret.auto.tfvars` contains plaintext locally but is gitignored
- **Encrypted at rest**: Parameter Store encrypts with dedicated KMS key
- **Access control**: KMS key controls who can decrypt SOPS files + Parameter Store access
- **Kubernetes secrets**: ESO creates standard secrets that apps consume normally

## SOPS Configuration

The `.sops.yaml` file automatically uses the KMS key for encryption. To manually encrypt:

```bash
# Encrypt in place
sops -e -i secrets.enc.yaml

# Edit encrypted file
sops secrets.enc.yaml
```

## Cost

Parameter Store SecureString parameters are free up to 10,000 parameters (as opposed to AWS secrets manager, which is horribly expensive).