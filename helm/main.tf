data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform/terraform.tfstate"
  }
}

locals {
  host        = data.terraform_remote_state.infra.outputs.k3s_endpoint
  kube_config = data.terraform_remote_state.infra.outputs.kube_config
  traefik_ip  = "192.168.1.220"
}

provider "helm" {
  kubernetes {
    host                   = local.host
    cluster_ca_certificate = local.kube_config.cluster_ca_certificate
    client_certificate     = local.kube_config.client_certificate
    client_key             = local.kube_config.client_key
  }
}

variable "cloudflare_api_key" {
  type      = string
  sensitive = true
}

variable "cloudflare_email" {
  type = string
}
variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}
variable "cloudflare_domain" {
  type = string
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cloudflare"
  create_namespace = true
  chart            = "cert-manager"
  version          = "v1.17.0"
  repository       = "https://charts.jetstack.io"

  set {
    name  = "installCRDs"
    value = true
  }
}

resource "helm_release" "cloudflare" {
  name             = "cloudflare"
  namespace        = "cloudflare"
  create_namespace = true
  chart            = "${path.module}/charts/cloudflare"

  depends_on = [helm_release.cert_manager]

  set {
    name  = "apiKeySecret.value"
    value = var.cloudflare_api_key
  }

  set {
    name  = "apiTokenSecret.value"
    value = var.cloudflare_api_token
  }

  set {
    name  = "cluster-issuer.cloudflareEmail"
    value = var.cloudflare_email
  }

  set {
    name  = "cloudflare-ddns.domains"
    value = var.cloudflare_domain
  }
}


resource "helm_release" "nginx" {
  name             = "nginx"
  namespace        = "nginx"
  create_namespace = true
  chart            = "${path.module}/charts/nginx"

  depends_on = [helm_release.cert_manager]

  set {
    name  = "hostname"
    value = "nginx.${var.cloudflare_domain}"
  }

  set {
    name  = "clusterIssuer.name"
    value = "cloudflare"
  }
}


# resource "helm_release" "longhorn" {
#   name             = "longhorn"
#   namespace        = "longhorn-system"
#   create_namespace = true
#   chart            = "longhorn"
#   version          = "v1.8.1"
#   repository       = "https://charts.longhorn.io"
# }
