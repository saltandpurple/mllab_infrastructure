terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "~>2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.12"
    }
  }
}