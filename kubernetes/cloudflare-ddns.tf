variable "cloudflare_api_token" {
    type     = string
    sensitive = true
}

resource "kubernetes_secret" "cloudflare_api_token" {
    metadata {
      name = "cloudflare-api-token-secret"
      namespace = local.cloudflare_namespace
    }

    type = "Opaque"
    data = {
      "api-token" : var.cloudflare_api_token
    }
}

locals {
  cloudflare_api_token_secret = kubernetes_secret.cloudflare_api_token.metadata[0].name
}

resource "kubectl_manifest" "ddns" {
  yaml_body = templatefile("${path.module}/templates/cloudflare-ddns.yml.tftpl", {
    namespace      = local.cloudflare_namespace
    api_token_secret = local.cloudflare_api_token_secret
    domains        = var.cloudflare_domain_name
  })
}
