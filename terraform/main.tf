terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
  }
}

locals {
  lxc_ips = [
    "192.168.1.80",
    "192.168.1.81",
    "192.168.1.82",
  ]
}

provider "kubectl" {
  host                   = "https://${var.k3s_vip}:6443"
  cluster_ca_certificate = module.k3s_master.kube_config.cluster_ca_certificate
  client_certificate     = module.k3s_master.kube_config.client_certificate
  client_key             = module.k3s_master.kube_config.client_key
  load_config_file       = false
}

provider "proxmox" {
  pm_api_url          = "http://${var.pm_ip}:8006/api2/json"
  pm_api_token_id     = "${var.pm_api_user}!${var.pm_api_token_name}"
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
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

module "k3s_server" {
  count  = length(local.lxc_ips) - 1
  source = "./modules/k3s_server"

  lxc_ip              = module.proxmox_lxc[count.index + 1].lxc_ip
  lxc_private_key_pem = module.proxmox_lxc[count.index + 1].lxc_private_key_pem

  k3s_vip   = var.k3s_vip
  k3s_token = module.k3s_master.k3s_token
}

module "metallb" {
  source = "./modules/metallb"

  ip_address_range = var.k3s_lb_address_range
}

resource "local_file" "k3s_master_config" {
  content = replace(module.k3s_master.kube_config.file,
    "server: https://127.0.0.1:6443",
    "server: https://${module.k3s_master.k3s_master_ip}:6443"
  )
  filename = "${path.module}/.kube/k3s_master_config"
}

resource "local_file" "k3s_vip_config" {
  content = replace(module.k3s_master.kube_config.file,
    "server: https://127.0.0.1:6443",
    "server: https://${var.k3s_vip}:6443"
  )
  filename = "${path.module}/.kube/k3s_vip_config"
}

output "k3s_vip" {
  value = var.k3s_vip
}

output "kube_config" {
  value     = module.k3s_master.kube_config
  sensitive = true
}
