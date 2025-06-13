locals {
  kubeconfig = {
    apiVersion      = "v1"
    kind            = "Config"
    current-context = var.eks_cluster_name
    clusters = [{
      name = var.eks_cluster_name
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = var.eks_cluster_name
      context = {
        cluster = var.eks_cluster_name
        user    = var.eks_cluster_name
      }
    }]
  }
  kubeconfig_iam_users = {
    users = [{
      name = var.eks_cluster_name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "--region",
            data.aws_region.current.name,
            "eks",
            "get-token",
            "--cluster-name",
            var.eks_cluster_name,
            "--role-arn",
            data.aws_iam_session_context.current.issuer_arn
          ]
        }
      }
    }]
  }
}

resource "local_file" "kubeconfig_iam" {
  filename = "kubeconfig-${var.eks_cluster_name}"
  content  = yamlencode(merge(local.kubeconfig, local.kubeconfig_iam_users))
}
