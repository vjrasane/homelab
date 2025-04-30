terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
  }
}

data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform/terraform.tfstate"
  }
}

locals {
  k3s_vip     = data.terraform_remote_state.infra.outputs.k3s_vip
  kube_config = data.terraform_remote_state.infra.outputs.kube_config
}

provider "kubectl" {
  host                   = "https://${local.k3s_vip}:6443"
  cluster_ca_certificate = local.kube_config.cluster_ca_certificate
  client_certificate     = local.kube_config.client_certificate
  client_key             = local.kube_config.client_key
  load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = "https://${local.k3s_vip}:6443"
    cluster_ca_certificate = local.kube_config.cluster_ca_certificate
    client_certificate     = local.kube_config.client_certificate
    client_key             = local.kube_config.client_key
  }
}

# resource "helm_release" "nginx_ingress" {
#     name = "nginx-ingress"

#     repository = "https://helm.nginx.com/stable"
#     chart = "nginx-ingress"

#     create_namespace = true

#     namespace = "nginx-ingress"

#     set {
#         name  = "controller.extraArgs.enable-ssl-passthrough"
#         value = "true"
#     }
# }