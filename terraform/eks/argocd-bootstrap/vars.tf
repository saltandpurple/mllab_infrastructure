variable "eks_cluster_name" {
  type = string
}

variable "kubernetes_config_path" {
  type    = string
  default = "~/.kube/config"
}

variable "kubernetes_config_context" {
  type    = string
}