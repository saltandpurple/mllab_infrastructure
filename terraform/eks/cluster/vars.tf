variable "eks_cluster_name" {
  type        = string
}

variable "eks_cluster_version" {
  type = string
}

variable "vpc_id" {
  type        = string
}

variable "eks_cluster_subnet_ids" {
  type        = list(string)
  default     = null
  description = "If empty, will use all subnets with `private` in the name from the chosen VPC"
}

variable "control_plane_access_allowed_cidrs" {
  type        = list(string)
  description = "Any subnets permitted to access the control plane of the cluster. Since the control plane is exposed internally, 0.0.0.0/0 will not render it publicly accessible."
  default     = ["0.0.0.0/0"]
}

variable "eks_tags" {
  type    = map(any)
  default = {}
}

variable "coredns_addon_version" {
  type        = string
  description = "If empty, most recent version is used"
  default     = null
}

# variable "vpc_cni_addon_version" {
#   type        = string
#   description = "If empty, most recent version is used"
#   default     = null
# }

variable "kube_proxy_addon_version" {
  type        = string
  description = "If empty, most recent version is used"
  default     = null
}

variable "aws_ebs_csi_driver_addon_version" {
  type        = string
  description = "If empty, most recent version is used"
  default     = null
}