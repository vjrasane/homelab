
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
  }
}

variable "domain_names" {
  type = list(string)
}

variable "namespace" {
  type = string
}

variable "issuer_name" {
  type = string
}

variable "secret_name" {
  type = string
}

locals {
  cert_manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = var.secret_name
      namespace = var.namespace
    }
    spec = {
      secretName = "nginx-cert"
      issuerRef = {
        kind = "ClusterIssuer"
        name = var.issuer_name
      }
      dnsNames = var.domain_names
    }
  }
}

resource "kubectl_manifest" "cert" {
  yaml_body = yamlencode(local.cert_manifest)
}

output "secret_name" {
  value = local.cert_manifest.spec.secretName
}

output "namespace" {
  value = local.cert_manifest.metadata.namespace
}

output "domain_names" {
  value = local.cert_manifest.spec.dnsNames
}
