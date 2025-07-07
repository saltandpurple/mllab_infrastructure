variable "kubernetes_config_path" {
  type    = string
  default = "~/.kube/config"
}

variable "kubernetes_config_context" {
  type    = string
  default = "mllab"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster name, used for conditions in the Karpenter IRSA IAM Policy."
}

variable "eks_cluster_subnet_ids" {
  type        = list(string)
  description = "List of Subnet IDs that will be used for any karpenter EC2 node."
}

variable "ebs_kms_key_id" {
  type        = string
  description = "KMS Key ID that will be used for root volumes of any karpenter EC2 node."
}

variable "eks_node_availability_zones" {
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  description = "(Optional) List of AZs in which karpenter will create EC2 nodes."
}

variable "karpenter_helm_release_version" {
  type        = string
  description = "Version of Karpenter (and CRDs) that will be installed."
}

variable "cluster_endpoint" {
  type = string
  description = "Cluster https endpoint"
}

variable "cluster_certificate_authority_data" {
  type = string
}

variable "eks_oidc_provider_arn" {
  type = string
  description = "OIDC provider ARN of the cluster this is installed to"
}