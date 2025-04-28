terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

locals {
  lxc_ips = [
    "192.168.1.80",
    # "192.168.1.81",
    # "192.168.1.82",
  ]
}

provider "proxmox" {
  pm_api_url          = "http://${var.pm_ip}:8006/api2/json"
  pm_api_token_id     = "${var.pm_api_user}!${var.pm_api_token_name}"
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

resource "local_file" "k3s_master_config" {
  content  = module.k3s_master.kube_config
  filename = "${path.module}/.kube/k3s_master_config"
}

provider "kubernetes" {
  alias                  = "k3s_master"
  host                   = "https://${module.k3s_master.k3s_master_ip}:6443"
  # token                  = module.k3s_master.k3s_token
  # cluster_ca_certificate = base64decode(yamldecode(module.k3s_master.kube_config)["clusters"][0]["cluster"]["certificate-authority-data"])
  # cluster_ca_certificate = 
  token = module.k3s_master.k3s_token
  config_path = local_file.k3s_master_config.filename
}

provider "kubectl" {
  alias                  = "k3s_master"
  host                   = "https://${module.k3s_master.k3s_master_ip}:6443"
  token                  = module.k3s_master.k3s_token
  # cluster_ca_certificate = base64decode(yamldecode(module.k3s_master.kube_config)["clusters"][0]["cluster"]["certificate-authority-data"])
  config_path = local_file.k3s_master_config.filename
}

module "proxmox_lxc" {
  count = length(local.lxc_ips)

  source = "./modules/proxmox_lxc"

  pm_ip        = var.pm_ip
  pm_node_name = var.pm_node_name
  pm_user      = var.pm_user
  pm_password  = var.pm_password

  lxc_ip              = local.lxc_ips[count.index]
  lxc_vmid            = 100 + count.index
  lxc_default_gateway = var.lxc_default_gateway
}

module "k3s_master" {
  source = "./modules/k3s_master"

  lxc_ip              = module.proxmox_lxc[0].lxc_ip
  lxc_private_key_pem = module.proxmox_lxc[0].lxc_private_key_pem
  k3s_vip             = var.k3s_vip

  depends_on = [module.proxmox_lxc]
}

module "kube_vip" {
  source = "./modules/kube_vip"

  k3s_vip = var.k3s_vip

  providers = {
    kubernetes = kubernetes.k3s_master
    kubectl    = kubectl.k3s_master
  }
}

# module "k3s_server" {
#   count  = length(local.lxc_ips) - 1
#   source = "./modules/k3s_server"

#   lxc_ip              = module.proxmox_lxc[count.index + 1].lxc_ip
#   lxc_private_key_pem = module.proxmox_lxc[count.index + 1].lxc_private_key_pem

#   k3s_vip   = var.k3s_vip
#   k3s_token = module.k3s_master.k3s_token
# }

output "k3s_token" {
  value     = module.k3s_master.k3s_token
  sensitive = true
}



