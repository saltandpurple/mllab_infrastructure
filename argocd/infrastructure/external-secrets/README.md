# External Secrets (Operator) 

## Files
- `secretstore.yaml` - Defines how to connect to AWS Parameter Store
- `externalsecret.yaml` - Example of syncing secrets from Parameter Store to Kubernetes secrets

## Usage
1. First apply the SecretStore:
   ```bash
   kubectl apply -f secretstore.yaml
   ```

2. Then apply the ExternalSecret:
   ```bash
   kubectl apply -f externalsecret.yaml
   ```

3. Check that the secret was created:
   ```bash
   kubectl get secret example-secret -n external-secrets -o yaml
   ```

## Prerequisites
- External Secrets Operator must be installed and running
- IAM role must be configured with appropriate permissions to access Parameter Store
- The secrets must exist in AWS Parameter Store under `/mllab/example/` path