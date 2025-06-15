output "ebs_kms_key_statements" {
  description = "KMS Permissions needed by Karpenter. Can be directly used by the [terraform-aws-kms](https://registry.terraform.io/modules/terraform-aws-modules/kms/aws/latest) module."
  value = [
    {
      sid = "EC2AccessRequiredByKarpenter"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:DescribeKey",
      ]
      resources = ["*"]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          values   = ["ec2.${data.aws_region.current.name}.amazonaws.com"]
          variable = "kms:ViaService"
        },
        {
          test     = "StringEquals"
          values   = [data.aws_caller_identity.current.account_id]
          variable = "kms:CallerAccount"
        }
      ]
    }
  ]
}

output "ebs_kms_key_policy_json" {
  description = "Alternative for the `ebs_kms_key_statements` output if a json representation is needed."
  value       = data.aws_iam_policy_document.ebs_kms_policy.json
}

output "karpenter_node_iam_role_arn" {
  description = "Needs to be configured as an input for the `var.aws_auth_node_iam_role_arns_non_windows` of the EKS module."
  value       = module.karpenter_aws_resources.node_iam_role_arn
}

output "karpenter_node_iam_role_name" {
  description = "Useful for attaching additional permissions to the instance role."
  value       = module.karpenter_aws_resources.node_iam_role_name
}

output "karpenter_bottlerocket_nodeclass_name" {
  description = "Name of the default BottleRocket EC2NodeClass used by the NodePools (if you want to define additional ones outside the module)."
  value       = kubectl_manifest.karpenter_bottlerocket_node_class.name
}

output "karpenter_amazonlinux_nodeclass_name" {
  description = "Name of the default BottleRocket EC2NodeClass used by the NodePools (if you want to define additional ones outside the module)."
  value       = kubectl_manifest.karpenter_amazon_linux_node_class.name
}

output "eks_node_availability_zones" {
  value = var.eks_node_availability_zones
}

output "cluster_endpoint" {
  value = data.aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = data.aws_eks_cluster.this.certificate_authority[0].data
}

output "eks_cluster_name" {
  value = var.eks_cluster_name
}

output "instance_profile_name" {
  value = module.karpenter_aws_resources.instance_profile_name
}
