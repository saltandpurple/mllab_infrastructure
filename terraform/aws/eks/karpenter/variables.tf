variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster name, used for conditions in the Karpenter IRSA IAM Policy."
}

variable "eks_cluster_subnet_ids" {
  type        = list(string)
  description = "List of Subnet IDs that should be used for any karpenter EC2 node."
}

variable "ebs_kms_key_id" {
  type        = string
  description = "(Optional) KMS Key ID that will be used for root volumes of any karpenter EC2 node, if empty the AWS managed KMS key will be used. Check the output `ebs_kms_key_statements` for necessary permissions."
  default     = null
}

variable "eks_node_availability_zones" {
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  description = "(Optional) List of AZs in which karpenter will create EC2 nodes."
}

variable "karpenter_helm_release_version" {
  type        = string
  default     = "1.2.0"
  description = "(Optional) Version of Karpenter (and CRDs) that will be installed."
}

variable "nodeclass_metadata_options" {
  type = object({
    httpEndpoint            = optional(string, "enabled")
    httpProtocolIPv6        = optional(string, "disabled")
    httpPutResponseHopLimit = optional(number, 2)
    httpTokens              = optional(string, "required")
  })
  description = "AWS IMDS setting for the `bottlerocket` and `AL2` EC2NodeClass"
  default = {}
}
