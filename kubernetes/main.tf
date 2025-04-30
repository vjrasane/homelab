terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
  }
}

variable "k3s_lb_address_range" {
  type    = string
  default = "192.168.1.200-192.168.1.220"
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
  alias                  = "k3s"
  host                   = "https://${local.k3s_vip}:6443"
  cluster_ca_certificate = local.kube_config.cluster_ca_certificate
  client_certificate     = local.kube_config.client_certificate
  client_key             = local.kube_config.client_key
  load_config_file       = false
}

module "metallb" {
  source = "../modules/metallb"

  ip_address_range = var.k3s_lb_address_range

  providers = {
    kubectl = kubectl.k3s
  }
}

