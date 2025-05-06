resource "kubernetes_namespace" "cloudflare" {
  metadata {
    name = "cloudflare"
  }
}

locals {
  cloudflare_namespace = kubernetes_namespace.cloudflare.metadata[0].name
}

resource "kubernetes_secret" "cloudflare_api_key" {
  metadata {
    name      = "cloudflare-api-key-secret"
    namespace = local.cloudflare_namespace
  }

  type = "Opaque"
  data = {
    "api-key" : var.cloudflare_api_key
  }
}

locals {
   cloudflare_api_key_secret = kubernetes_secret.cloudflare_api_key.metadata[0].name
}

resource "helm_release" "cert_manager" {
  name      = "cert-manager"
  namespace = local.cloudflare_namespace

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = templatefile("${path.module}/templates/cluster-issuer.yml.tftpl", {
    namespace         = local.cloudflare_namespace
    cloudflare_email  = var.cloudflare_email
    cloudflare_api_key_secret = local.cloudflare_api_key_secret
  }) 
  depends_on = [helm_release.cert_manager]
}
