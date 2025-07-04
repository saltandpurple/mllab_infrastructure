# MLLab Infrastructure

This repository contains Terraform infrastructure code for deploying a complete AWS EKS-based machine learning platform. The infrastructure is designed to be deployed in the correct sequence: VPC � EKS Cluster � Karpenter.

## Architecture Overview

The infrastructure consists of three main components:

1. **VPC** - Network foundation with public/private subnets across 3 AZs
2. **EKS Cluster** - Kubernetes cluster with Fargate profiles and essential addons
3. **Karpenter** - Node autoscaling solution for dynamic EC2 instance provisioning

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
- VPC with CIDR `100.100.0.0/16`
- 3 public subnets across AZs (`100.100.0.0/19`, `100.100.32.0/19`, `100.100.64.0/19`)
- 3 private subnets across AZs (`100.100.128.0/19`, `100.100.160.0/19`, `100.100.192.0/19`)
- Internet Gateway for public subnets
- NAT Gateway with Elastic IP for private subnet internet access
- VPC endpoints for S3 and DynamoDB
- Route tables and associations

**Key files:**
- `terraform/aws/vpc/main.tf` - VPC resources definition
- `terraform/aws/vpc/variables.tf` - Input variables
- `terraform/aws/vpc/terraform.tfvars` - Variable values
- `terraform/aws/vpc/locals.tf` - Route table configuration

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

**Key features:**
- Mixed authentication mode (API and ConfigMap)
- CloudWatch logging with 14-day retention
- Encrypted EBS volumes using dedicated KMS key
- Security group policies for proper Fargate networking

**Key files:**
- `terraform/aws/eks/cluster/main.tf` - EKS cluster and addon configuration
- `terraform/aws/eks/cluster/vars.tf` - Input variables
- `terraform/aws/eks/cluster/terraform.tfvars` - Variable values

### 3. Karpenter Node Autoscaling

Deploy Karpenter for dynamic node provisioning:

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
- Default EC2NodeClass (`al2-default`) configuration:
  - Amazon Linux 2 AMI
  - 100GB encrypted GP3 root volume
  - Instance store RAID0 configuration
- ARM64 NodePool (`arm64-default`) with:
  - On-demand instances only  
  - Instance families: r8g, r7g, r6g, m7g, m8g
  - Instance sizes: medium, large, xlarge
  - Resource limits: 12 CPU, 96Gi memory
  - Consolidation policy for cost optimization

**Key features:**
- Spot termination handling via SQS
- Drift detection enabled
- Optimized batching (10s max duration, 1s idle duration)
- Debug logging enabled
- Resource consolidation after 1 hour of underutilization

**Key files:**
- `terraform/aws/eks/karpenter/main.tf` - Karpenter controller and AWS resources
- `terraform/aws/eks/karpenter/nodepools.tf` - NodePool and EC2NodeClass definitions
- `terraform/aws/eks/karpenter/variables.tf` - Input variables
- `terraform/aws/eks/karpenter/terraform.tfvars` - Variable values

## Configuration

### VPC Configuration
```hcl
name = "Primary"
vpc_primary_cidr = "100.100.0.0/16"
public_subnet_cidrs = ["100.100.0.0/19", "100.100.32.0/19", "100.100.64.0/19"]
private_subnet_cidrs = ["100.100.128.0/19", "100.100.160.0/19", "100.100.192.0/19"]
```

### EKS Configuration
```hcl
eks_cluster_name = "mllab"
eks_cluster_version = "1.32"
vpc_id = "vpc-0a7cae9e440c19e40"  # Output from VPC deployment
eks_cluster_subnet_ids = [        # Private subnets from VPC deployment
  "subnet-0c6b1d344e392b7c5",
  "subnet-0ddc4b4c537a8f120", 
  "subnet-073aa63eedad20a46"
]
```

### Karpenter Configuration
```hcl
eks_cluster_name = "mllab"
eks_cluster_subnet_ids = [        # Same as EKS cluster subnets
  "subnet-0c6b1d344e392b7c5",
  "subnet-0ddc4b4c537a8f120",
  "subnet-073aa63eedad20a46"
]
karpenter_helm_release_version = "1.3.4"
```

## Post-Deployment

After successful deployment:

1. Update your kubeconfig:
   ```bash
   aws eks update-kubeconfig --name mllab --region eu-central-1
   ```

2. Verify cluster connectivity:
   ```bash
   kubectl get nodes
   kubectl get pods -n kube-system
   ```

3. Test Karpenter by deploying workloads that require scaling:
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: test-app
   spec:
     replicas: 5
     selector:
       matchLabels:
         app: test-app
     template:
       metadata:
         labels:
           app: test-app
       spec:
         containers:
         - name: app
           image: nginx
           resources:
             requests:
               cpu: 1
               memory: 1Gi
   EOF
   ```

## Directory Structure

```
terraform/
   aws/
      vpc/                  # VPC infrastructure
      eks/
          cluster/          # EKS cluster configuration
          karpenter/        # Karpenter autoscaling
   [state-files]/           # Terraform state files (gitignored)
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
- **Karpenter not scaling**: Check node requirements and available instance types
- **Permission issues**: Verify IRSA roles and policies are correctly configured
- **Network connectivity**: Confirm security group rules allow required traffic

## Contributing

When making changes to the infrastructure:

1. Update variable descriptions and defaults as needed
2. Test changes in a non-production environment first
3. Update this README to reflect any architectural changes
4. Follow the existing naming conventions and tagging strategies