provider aws {
  region = "eu-central-1"
  profile = "df"
}
# This provider config is based on the assumption that the kubeconfig has already been set up properly
provider "kubectl" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_config_context
}

provider "helm" {
  kubernetes {
    config_path = var.kubernetes_config_path
  }
}