# After running this, a manual setup of the connection between argocd and the first repo is required

data "http" "application-crd" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/crds/application-crd.yaml"
}

data "http" "applicationset-crd" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/crds/applicationset-crd.yaml"
}

data "http" "appproject-crd" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/crds/appproject-crd.yaml"
}

resource "kubectl_manifest" "application-crd" {
  yaml_body = data.http.application-crd.response_body
}

resource "kubectl_manifest" "applicationset-crd" {
  yaml_body = data.http.applicationset-crd.response_body
}

resource "kubectl_manifest" "appproject-crd" {
  yaml_body = data.http.appproject-crd.response_body
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = "true"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.1.0"

  set {
    name  = "crds.install"
    value = false
  }

  timeout = 600

  depends_on = [kubectl_manifest.application-crd, kubectl_manifest.appproject-crd, kubectl_manifest.applicationset-crd]
}


resource "kubectl_manifest" "application_of_applications" {
  depends_on = [helm_release.argocd]
  yaml_body  = <<YAML
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: applications
        namespace: argocd
      spec:
        project: default
        source:
          repoURL: 'https://github.com/saltandpurple/mllab_infrastructure'
          path: argocd/infrastructure/_manifests
          targetRevision: master
        destination:
          server: 'https://kubernetes.default.svc'
          namespace: argocd

    YAML
}