# MLLab Infrastructure

This repository contains Terraform infrastructure code for deploying a complete AWS EKS-based machine learning platform. The infrastructure is designed to be deployed in the correct sequence: VPC � EKS Cluster � Karpenter.

## Architecture Overview

The infrastructure consists of three main components:

1. **VPC** - Network foundation with public/private subnets across 3 AZs
2. **EKS Cluster** - Kubernetes cluster with Fargate profiles and essential addons
3. **Karpenter** - Node autoscaling solution for dynamic EC2 instance provisioning
4. **ArgoCD Bootstrap** - Initial setup of ArgoCD + corresponding AoA
5. **Secrets** - Secret handling via encrypted SSM parameter store and External Secret Operator

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- kubectl
- Helm 3.x

## Deployment Sequence

### 1. VPC Infrastructure

Deploy the VPC first to establish the network foundation:

```bash
cd terraform/aws/vpc
terraform init
terraform plan
terraform apply
```

**What it creates:**
- VPC 
- 3 public subnets across AZs 
- 3 private subnets across AZs 
- NAT Gateway with Elastic IP for private subnet internet access
- VPC endpoints for S3 and DynamoDB
- Route tables and associations

### 2. EKS Cluster

Deploy the EKS cluster using the VPC infrastructure:

```bash
cd terraform/aws/eks/cluster
terraform init
terraform plan
terraform apply
```

**What it creates:**
- EKS cluster `mllab` running Kubernetes 1.32
- Fargate profile for `kube-system` namespace with label `ml.lab/runOnFargate: true`
- Essential cluster addons:
  - CoreDNS (configured for Fargate)
  - kube-proxy
  - AWS EBS CSI Driver
- IRSA (IAM Roles for Service Accounts) for:
  - VPC CNI
  - EBS CSI Controller
  - AWS Load Balancer Controller
- KMS key for EBS encryption
- Security groups with additional ingress rules for HTTP traffic
- SecurityGroupPolicy for Fargate pods

### 3. Karpenter Node Autoscaling

Deploy Karpenter

```bash
cd terraform/aws/eks/karpenter
terraform init
terraform plan
terraform apply
```

**What it creates:**
- Karpenter controller running on Fargate (2 replicas)
- IRSA for Karpenter with necessary EC2 permissions
- SQS queue for spot instance interruption notifications
- Instance profile for Karpenter-managed nodes
- Default EC2NodeClass (`al2-default`)
- ARM64 NodePool (`arm64-default`) with:
  - Spot instances only  
  - Instance families: r8g, r7g, r6g, m7g, m8g
  - Instance sizes: medium, large, xlarge
  - Consolidation policy for cost optimization

**Key features:**
- Spot termination handling via SQS
- Drift detection enabled
- Optimized batching (10s max duration, 1s idle duration)
- Resource consolidation after 1 hour of underutilization

**Known issues**

- `Error: arm64-default failed to create kubernetes rest client for update of resource: resource [karpenter.sh/v1/NodePool] isn't valid for cluster, check the APIVersion and Kind fields are valid`
-> You might have to re-apply the manifest after CRDs have been created

- Karpenter not scaling
-> Check node requirements and available instance types

## Post-Deployment

After successful deployment:

1. Update your kubeconfig:
   ```bash
   aws eks update-kubeconfig --name mllab --region eu-central-1
   ```

2. Verify cluster connectivity:
   ```bash
   kubectl get pods
   ```


## Important Notes

- **Deployment Order**: Always follow VPC � EKS � Karpenter sequence
- **Region**: Infrastructure is configured for `eu-central-1`
- **Fargate**: System components run on Fargate (no EC2 worker nodes by default)
- **Scaling**: Karpenter provisions ARM64 instances for application workloads
- **Security**: All EBS volumes are encrypted with dedicated KMS keys
- **Cost Optimization**: Karpenter consolidates underutilized nodes automatically

## Troubleshooting

- **Fargate pods not starting**: Ensure pods have the label `ml.lab/runOnFargate: true`

- **Permission issues**: Verify IRSA roles and policies are correctly configured
- **Network connectivity**: Confirm security group rules allow required traffic