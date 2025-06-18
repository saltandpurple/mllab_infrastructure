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
  cluster_endpoint_public_access  = true
  cluster_additional_security_group_ids = concat(
    [aws_security_group.eks_control_plane_additional_rules.id],
  )

  cloudwatch_log_group_retention_in_days = 14
  create_cloudwatch_log_group            = true
  dataplane_wait_duration                = "10m"

  kms_key_enable_default_policy = true

  authentication_mode = "API_AND_CONFIG_MAP" # default
  enable_irsa         = true

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

# Fargate nodes need to use the correct SG
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


# IRSA
module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~>5.58"

  # role_name_prefix      = "eks-${var.eks_cluster_name}-vpc-cni-irsa"
  role_name             = "eks-${var.eks_cluster_name}-cni-role"
  policy_name_prefix    = "eks-${var.eks_cluster_name}-vpc-cni-policy"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true
  vpc_cni_enable_ipv6   = false

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

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

module "aws_lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~>5.33"

  role_name                              = "eks-${var.eks_cluster_name}-aws-lb-controller-irsa"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~>5.33"

  role_name = "eks-${var.eks_cluster_name}-external-secrets-irsa"

  # Custom policy for accessing Parameter Store
  role_policy_arns = {
    ssm_policy = aws_iam_policy.external_secrets_ssm_policy.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets-operator"]
    }
  }
}

# IAM policy for External Secrets to access Parameter Store
resource "aws_iam_policy" "external_secrets_ssm_policy" {
  name        = "eks-${var.eks_cluster_name}-external-secrets-ssm"
  description = "Policy for External Secrets Operator to access Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/mllab/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "arn:aws:kms:*:*:key/*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ssm.*.amazonaws.com"
          }
        }
      }
    ]
  })
}

# todo: s3 policy

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





