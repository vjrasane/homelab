terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
  }
}

variable "ip_address_range" {
  type = string
}

data "kubectl_file_documents" "metallb" {
  content = file("${path.module}/manifests/metallb-native.yml")
}

resource "kubectl_manifest" "metallb" {
  count = length(data.kubectl_file_documents.metallb.documents)
  yaml_body = element(data.kubectl_file_documents.metallb.documents, count.index)
}

resource "kubectl_manifest" "address_pool" {
    yaml_body = templatefile("${path.module}/templates/metallb-address-pool.yml.tftpl", {
      ip_address_range = var.ip_address_range
    })

    depends_on = [kubectl_manifest.metallb]
}