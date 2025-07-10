locals {
  default_nodepool_config = {
    nodeClassRef = {
      group = "karpenter.k8s.aws"
      kind  = "EC2NodeClass"
      name  = "al2-default"
    }
    requirements = [
      {
        key      = "topology.kubernetes.io/zone"
        operator = "In"
        values   = var.eks_node_availability_zones
      },
      {
        key      = "karpenter.k8s.aws/instance-local-nvme"
        operator = "DoesNotExist"
      },
    ]

    disruption = {
      consolidationPolicy = "WhenEmptyOrUnderutilized"
      consolidateAfter    = "1h"
      expireAfter         = "${14 * 24}h"
    }
    terminationGracePeriod = "1h"
    limits = {
      cpu    = "12"
      memory = "96Gi"
    }
  }
}


resource "kubectl_manifest" "karpenter_amazon_linux_node_class" {
  provider = kubectl
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "al2-default"
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
            volumeSize = "50Gi"
            volumeType = "gp3"
            encrypted  = true
            kmsKeyID   = var.ebs_kms_key_id
          }
        },
      ]
      # https://karpenter.sh/v1.2/concepts/nodeclasses/#specinstancestorepolicy
      instanceStorePolicy = "RAID0"
      detailedMonitoring = false
      metadataOptions = {
        httpEndpoint = "enabled"
        httpProtocolIPv6 = "disabled"
        httpPutResponseHopLimit = 2 # required to allow metadata access from pods
        httpTokens = "required"
      }
    }
  })

  depends_on = [
    helm_release.karpenter_crd,
  ]
}

resource "kubectl_manifest" "karpenter_nodepool_spot" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "arm64-default"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = local.default_nodepool_config.nodeClassRef
          requirements = concat(local.default_nodepool_config.requirements, [
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["arm64"]
            },
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot"]
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              # values   = ["t4g", "r7g", "r6g", "m7g", "m8g"]
              values   = ["t4g"]
            },
            
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              values = ["large", "xlarge"]
            },
            {
              key      = "karpenter.k8s.aws/instance-local-nvme"
              operator = "DoesNotExist"
            },
          ])
        }
      }
      terminationGracePeriod = local.default_nodepool_config.terminationGracePeriod
      disruption = local.default_nodepool_config.disruption
      limits     = local.default_nodepool_config.limits
    }
  })

}
