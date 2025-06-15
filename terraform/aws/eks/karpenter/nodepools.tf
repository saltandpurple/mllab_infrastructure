locals {
  default_nodepool_config = {
    nodeClassRef = {
      group = "karpenter.k8s.aws"
      kind  = "EC2NodeClass"
      name  = "arm64_default"
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

# todo: properly spec this
resource "kubectl_manifest" "karpenter_nodepool_ondemand" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "ondemand-arm64"
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
              values   = ["on-demand"]
            },
            {
              key      = "karpenter.k8s.aws/instance-family"
              operator = "In"
              values   = ["r7g", "r6g"]
            },
            {
              key      = "karpenter.k8s.aws/instance-size"
              operator = "In"
              # Since we hardcode the maxPods to 110, do not use `medium`,
              # any large or higher instance can run at least 110 pods.
              values = ["large", "xlarge", "2xlarge"]
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
