data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" { arn = data.aws_caller_identity.current.arn }
data "aws_security_group" "sg_eks_worker_node" {
  filter {
    name   = "tag:Name"
    values = ["${var.eks_cluster_name}-node"]
  }
}
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}
