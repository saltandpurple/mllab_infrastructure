variable "subnet_id" {
  type = string
  description = "The subnet the bastion host will be provisioned in"
}

variable "key_name" {
  type = string
  description = "The name of the key pair to use for the bastion host"
}