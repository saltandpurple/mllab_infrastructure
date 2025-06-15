module "karpenter_aws_resources" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~>20.37"

  cluster_name = var.eks_cluster_name
  enable_irsa            = true
  enable_pod_identity    = false
  create_iam_role        = true
  create_access_entry    = true
  irsa_oidc_provider_arn = local.eks_oidc_provider_arn
  # Using the kube-system namespace to avoid rate limiting from the EKS APIServer.
  irsa_namespace_service_accounts = ["kube-system:karpenter"]
  create_instance_profile         = true
  node_iam_role_attach_cni_policy = true 
  enable_spot_termination   = true
  queue_managed_sse_enabled = true
}

resource "helm_release" "karpenter_crd" {
  chart            = "oci://public.ecr.aws/karpenter/karpenter-crd"
  name             = "karpenter-crd"
  namespace        = "kube-system"
  create_namespace = false
  version          = var.karpenter_helm_release_version
  # values = [yamlencode({
  #   webhook = {
  #     enabled          = true
  #     serviceName      = "karpenter"
  #     serviceNamespace = "kube-system"
  #     port             = 8443
  #   }
  # })]
}

resource "helm_release" "karpenter" {
  chart            = "oci://public.ecr.aws/karpenter/karpenter"
  name             = "karpenter"
  namespace        = "kube-system"
  create_namespace = false
  version          = var.karpenter_helm_release_version
  skip_crds        = true

  # https://github.com/aws/karpenter-provider-aws/blob/main/charts/karpenter/values.yaml
  values = [yamlencode({
    serviceAccount = {
      create = true
      name   = "karpenter"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.karpenter_aws_resources.iam_role_arn
      }
    }
    serviceMonitor = {
      enabled = true
    }
    replicas = 2
    podLabels = {
      "ml.lab/runOnFargate" = "true"
    }
    controller = {
      resources = {
        requests = {
          cpu    = "0.5"
          memory = "768Mi"
        }
      }
    }
    settings = {
      clusterName = var.eks_cluster_name
      logLevel    = "debug"
      # -- The maximum length of a batch window. The longer this is, the more pods we can consider for provisioning at one
      # time which usually results in fewer but larger nodes.
      batchMaxDuration = "10s"
      # -- The maximum amount of time with no new ending pods that if exceeded ends the current batching window. If pods arrive
      # faster than this time, the batching window will be extended up to the maxDuration. If they arrive slower, the pods
      # will be batched separately.
      batchIdleDuration = "1s"
      vmMemoryOverheadPercent = "0.075"
      interruptionQueue = module.karpenter_aws_resources.queue_name
      featureGates = {
        drift = true
      }
    }
  })]

  depends_on = [
    helm_release.karpenter_crd
  ]
}

resource "kubectl_manifest" "karpenter_amazon_linux_node_class" {
  provider = kubectl
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default-al2"
    }
    spec = {
      amiFamily = "AL2"
      amiSelectorTerms = [{
        alias = "al2@latest"
      }]
      subnetSelectorTerms = [
        for subnet_id in var.eks_cluster_subnet_ids : {
          id = subnet_id
        }
      ]
      securityGroupSelectorTerms = [{
        id = data.aws_security_group.sg_eks_worker_node.id
      }]
      instanceProfile = module.karpenter_aws_resources.instance_profile_name
      blockDeviceMappings = [
        {
          # Root device
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize = "100Gi"
            volumeType = "gp3"
            encrypted  = true
            kmsKeyID   = var.ebs_kms_key_id
          }
        },
      ]
      # https://karpenter.sh/v1.2/concepts/nodeclasses/#specinstancestorepolicy
      instanceStorePolicy = "RAID0"
      metadataOptions = var.nodeclass_metadata_options
      detailedMonitoring = false
    }
  })

  depends_on = [
    helm_release.karpenter_crd,
  ]
}


## Permission stuff
# Permission to create EC2 instances and launch templates, limited by Tag:
#    kubernetes.io/cluster/<var.eks_cluster_name> = owned
# Creates and grants Access to SQS which provides advanced warning for Spot
# Interruption events (~2min).
# https://karpenter.sh/docs/concepts/disruption/#interruption
resource "aws_iam_service_linked_role" "karpenter_spot" {
  aws_service_name = "spot.amazonaws.com"
}

data "aws_iam_policy_document" "ebs_kms_policy" {
  statement {
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
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      values   = ["ec2.${data.aws_region.current.name}.amazonaws.com"]
      variable = "kms:ViaService"
    }
    condition {
      test     = "StringEquals"
      values   = [data.aws_caller_identity.current.account_id]
      variable = "kms:CallerAccount"
    }
  }
}