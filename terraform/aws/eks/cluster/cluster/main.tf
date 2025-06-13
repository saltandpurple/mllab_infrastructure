resource "aws_security_group" "eks_control_plane_additional_rules" {
  name        = "${var.eks_cluster_name}_eks_control_plane_additional_rules"
  description = "Additional rules for control plane"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow access to control plane"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.control_plane_access_allowed_cidrs
  }

  tags = {
    Name = "eks_control_plane_additional_rules"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36"

  cluster_name                             = var.eks_cluster_name
  cluster_version                          = var.eks_cluster_version
  enable_cluster_creator_admin_permissions = true

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false
  cluster_additional_security_group_ids = concat(
    [aws_security_group.eks_control_plane_additional_rules.id],
  )

  cloudwatch_log_group_retention_in_days = 14
  create_cloudwatch_log_group            = true
  dataplane_wait_duration                = "10m"

  # Delegates KMS Permissions to AWS IAM
  kms_key_enable_default_policy = true

  authentication_mode = "API_AND_CONFIG_MAP" # default
  enable_irsa         = true

  # Explanation for Fargate Pod Sizing
  # Important: Only requests matter, since the VM size for the Pod is
  #            determined during initial start of the Pod and
  #            _cannot be resized afterwards.
  # Read the documentation: https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
  # TL;DR:
  # - vCPU count determines the maximum Memory possible
  # - If you choose more memory than the vCPU count supports, a higher tier is chosen
  # - 256 MB is always added for the kubelet, kube-proxy and containerd
  # - The k8s node size _may_ be bigger than the capacity available for the pod:
  #   -> check the annotation "CapacityProvisioned" on the Pod
  fargate_profiles = {
    kube-system = {
      name          = "kube-system-apps"
      iam_role_name = "fargate-${var.eks_cluster_name}"
      selectors = [{
        namespace = "kube-system"
        labels = {
          "ml.lab/runOnFargate" = true
        }
      }]
    }
  }

  cluster_addons = {
    coredns = {
      # Setting preserve to true will retain config changes to addons when updating.
      preserve      = true
      most_recent   = var.coredns_addon_version == null ? true : false
      addon_version = var.coredns_addon_version

      configuration_values = jsonencode({
        computeType = "Fargate"
        podLabels = {
          "ml.lab/runOnFargate" = "true"
        }
      })
    }

    kube-proxy = {
      preserve      = true
      most_recent   = var.kube_proxy_addon_version == null ? true : false
      addon_version = var.kube_proxy_addon_version
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }

    aws-ebs-csi-driver = {
      preserve                 = true
      most_recent              = var.aws_ebs_csi_driver_addon_version == null ? true : false
      addon_version            = var.aws_ebs_csi_driver_addon_version
      service_account_role_arn = module.csi_irsa.iam_role_arn

      configuration_values = jsonencode({
        customLabels = {
          "ml.lab/runOnFargate" = "true"
        }
      })
    }
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.eks_cluster_subnet_ids

  node_security_group_additional_rules = {
    cluster_webhook_sealed_secrets = {
      description                   = "Cluster API to node 8080/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 8080
      to_port                       = 8080
      type                          = "ingress"
      source_cluster_security_group = true
    }

    # Many 3rd-party images expose port 80 hardcoded.
    # In order for them to be usable in our setup (without rebuilding of the image) we expose port 80 for node to node traffic.
    eks_ingress_http = {
      description              = "Allow node to node HTTP traffic"
      protocol                 = "tcp"
      from_port                = 80
      to_port                  = 80
      type                     = "ingress"
      source_security_group_id = module.eks.node_security_group_id
    }
  }
  tags = var.eks_tags
}

# --- Fargate Security Group Policy
# This makes sure that the pods running on Fargate use the
# node security group (otherwise they would use the cluster
# security group that should be attached to the control plane)
# Important: You might have to restart all fargate pods to make
# sure the correct one is attached.
# SG Used by the Pod can be found via annotation:
#   `fargate.amazonaws.com/pod-sg: sg-<ID>`
resource "kubectl_manifest" "fargate_kube_system_security_group_policy" {
  yaml_body = yamlencode({
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = "fargate-policy"
      namespace = "kube-system"
    }
    spec = {
      podSelector = {
        # EBS Addon will attach the label to every Pod (incld. the daemonset)
        # which in turn will require SecurityGroup for Pods support on nodes
        # (which we don't use at the moment).
        matchExpressions = [{
          key      = "app"
          operator = "NotIn"
          values   = ["ebs-csi-node"]
        }]
        matchLabels = {
          "ml.lab/runOnFargate" = "true"
        }
      }
      securityGroups = {
        groupIds = [module.eks.node_security_group_id]
      }
    }
  })
}

# resource "kubectl_manifest" "fargate_kyverno_security_group_policy" {
#   yaml_body = yamlencode({
#     apiVersion = "vpcresources.k8s.aws/v1beta1"
#     kind       = "SecurityGroupPolicy"
#     metadata = {
#       name      = "fargate-policy"
#       namespace = "kyverno"
#     }
#     spec = {
#       podSelector = {
#         matchLabels = {
#           "ml.lab/runOnFargate" = "true"
#         }
#       }
#       securityGroups = {
#         groupIds = [module.eks.node_security_group_id]
#       }
#     }
#   })
# }


# IRSA
# module "vpc_cni_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "~>5.33"
#
#   role_name_prefix      = var.vpc_cni_irsa_iam_role_name == null ? "eks-${var.eks_cluster_name}-vpc-cni-irsa" : null
#   role_name             = var.vpc_cni_irsa_iam_role_name
#   policy_name_prefix    = "eks-${var.eks_cluster_name}-vpc-cni-policy"
#   attach_vpc_cni_policy = true
#   vpc_cni_enable_ipv4   = true
#   vpc_cni_enable_ipv6   = false
#
#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:aws-node"]
#     }
#   }
#
#   tags = {
#     Name = "eks_cni_role"
#   }
# }

module "csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~>5.33"

  role_name             = "eks-${var.eks_cluster_name}-csi-irsa"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# EBS KMS Key
module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~>2.1"

  description = "EBS Key for ${var.eks_cluster_name}"
  key_usage   = "ENCRYPT_DECRYPT"

  # Delegates Permissions to AWS IAM
  enable_default_policy = true
  key_service_users = [
    module.csi_irsa.iam_role_arn,
  ]
  key_users = [
    module.csi_irsa.iam_role_arn,
  ]

  # Nodes require this to make use of encrypted EBS volumes.
  key_statements = [
    {
      sid    = "EC2Access"
      effect = "Allow"
      principals = [{
        type        = "AWS"
        identifiers = ["*"]
      }]
      actions = [
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt",
        "kms:CreateGrant"
      ]
      resources = ["*"]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values   = ["ec2.${data.aws_region.current.name}.amazonaws.com"]
        },
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  ]
  aliases = ["eks/ebs/${var.eks_cluster_name}"]
}





