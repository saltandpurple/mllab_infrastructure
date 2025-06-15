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

resource "aws_iam_policy" "karpenter_node_custom_policy" {
  name_prefix = "Karpenter-${var.eks_cluster_name}-node-custom-policy-"
  policy      = data.aws_iam_policy_document.karpenter_node_custom_policy.json
}

module "karpenter_aws_resources" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~>20.8"

  cluster_name = var.eks_cluster_name

  # IAM Karpenter Controller
  enable_irsa            = true
  enable_pod_identity    = false
  create_iam_role        = true
  create_access_entry    = true
  irsa_oidc_provider_arn = local.eks_oidc_provider_arn
  # Using the kube-system namespace to avoid rate limiting from the EKS APIServer.
  # Alternatively we would need to setup our own FlowSchemas
  # Further reading: https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/#preventing-apiserver-request-throttling
  irsa_namespace_service_accounts = ["kube-system:karpenter"]

  # IAM Role Node
  create_instance_profile         = true
  node_iam_role_attach_cni_policy = true # todo: check if this is still needed
  node_iam_role_additional_policies = {
    ssm           = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    custom_policy = aws_iam_policy.karpenter_node_custom_policy.arn
  }

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
      "neozo.cloud/runOnFargate" = "true"
    }
    controller = {
      resources = {
        # see note above regarding fargate sizing
        # This should be enough for most small clusters
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
      # -- The VM memory overhead as a percent that will be subtracted from the total memory for all instance types
      vmMemoryOverheadPercent = "0.075"
      # -- interruptionQueue is disabled if not specified. Enabling interruption handling may
      # require additional permissions on the controller service account. Additional permissions are outlined in the docs.
      interruptionQueue = module.karpenter_aws_resources.queue_name
      # -- Feature Gate configuration values. Feature Gates will follow the same graduation process and requirements as feature gates
      # in Kubernetes. More information here https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/#feature-gates-for-alpha-or-beta-features
      featureGates = {
        # -- drift is in BETA and is enabled by default.
        # Setting drift to false disables the drift disruption method to watch for drift between currently deployed nodes
        # and the desired state of nodes set in nodepools and nodeclasses
        # Adding annotation 'karpenter.sh/do-not-disrupt: "true"' to any Pod or Node disables drift for the Pod/Node.
        # Read More: https://karpenter.sh/docs/concepts/disruption/#controls
        drift = true
      }
    }
  })]

  depends_on = [
    helm_release.karpenter_crd
  ]
}

resource "kubectl_manifest" "karpenter_bottlerocket_node_class" {
  provider = kubectl
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "Bottlerocket"
      amiSelectorTerms = [{
        alias = "bottlerocket@latest"
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
      # Specific for Bottlerocket
      # https://karpenter.sh/docs/concepts/nodeclasses/#bottlerocket-1
      blockDeviceMappings = [
        {
          # Root device
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize = "4Gi"
            volumeType = "gp3"
            encrypted  = true
            kmsKeyID   = var.ebs_kms_key_id
          }
        },
        {
          # Data device: Container resources such as images and logs
          deviceName = "/dev/xvdb"
          ebs = {
            volumeSize = "100Gi"
            volumeType = "gp3"
            encrypted  = true
            kmsKeyID   = var.ebs_kms_key_id
          }
        }
      ]
      # https://karpenter.sh/v1.2/concepts/nodeclasses/#specinstancestorepolicy
      instanceStorePolicy = "RAID0"
      # Optional, configures IMDS for the instance
      metadataOptions = var.nodeclass_metadata_options
      # Optional, configures detailed monitoring for the instance
      detailedMonitoring = false
      kubelet = {
        # https://github.com/aws/karpenter-provider-aws/issues/2029
        # https://github.com/bottlerocket-os/bottlerocket/issues/1721
        # Karpenter does not detect (or allow the configuration) of custom-networking
        # with prefix delegation, which means the maxPods allocatable per Node are
        # fewer than actually possible Pods:
        #   r6g.large: 29 -> should be 110
        maxPods = 110
      }
    }
  })

  depends_on = [
    helm_release.karpenter_crd,
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
      # Specific for AL2
      # https://karpenter.sh/v1.2/concepts/nodeclasses/#al2-1
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
      # Optional, configures IMDS for the instance
      metadataOptions = var.nodeclass_metadata_options
      # Optional, configures detailed monitoring for the instance
      detailedMonitoring = false
    }
  })

  depends_on = [
    helm_release.karpenter_crd,
  ]
}
