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

locals {
  cluster_issuer_manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name      = "cloudflare-cluster-issuer"
      namespace = local.cloudflare_namespace
    }
    spec = {
      acme = {
        email  = var.cloudflare_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "cloudflare-cluster-issuer-account-key"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                email = var.cloudflare_email
                apiKeySecretRef = {
                  name = local.cloudflare_api_key_secret 
                  key  = "api-key"
                }
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = yamlencode(local.cluster_issuer_manifest)
  depends_on = [helm_release.cert_manager]
}
