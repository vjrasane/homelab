variable "hostname" {
  type = string
}

variable "user" {
  type    = string
  default = "root"
}

variable "private_key_pem" {
  type      = string
  sensitive = true
}

module "get_kube_config" {
  source = "../ssh_cmd"

  hostname        = var.hostname
  user            = var.user
  private_key_pem = var.private_key_pem
  # command         = "cat /etc/rancher/k3s/k3s.yaml | sed 's|server: https://127.0.0.1:6443|server: https://${var.k3s_server_hostname}:6443|'"
  command = "cat /etc/rancher/k3s/k3s.yaml"
}

output "cluster_ca_certificate" {
  value = base64decode(yamldecode(module.get_kube_config.result)["clusters"][0]["cluster"]["certificate-authority-data"])
}

output "client_certificate" {
  value = base64decode(yamldecode(module.get_kube_config.result)["users"][0]["user"]["client-certificate-data"])
}

output "client_key" {
  value = base64decode(yamldecode(module.get_kube_config.result)["users"][0]["user"]["client-key-data"])
}

locals {
  cluster_config = yamldecode(module.get_kube_config.result)["clusters"][0]["cluster"]
  user_config    = yamldecode(module.get_kube_config.result)["users"][0]["user"]
}

output "config" {
  value = {
    file                   = module.get_kube_config.result
    client_key             = base64decode(local.user_config["client-key-data"])
    client_certificate     = base64decode(local.user_config["client-certificate-data"])
    cluster_ca_certificate = base64decode(local.cluster_config["certificate-authority-data"])
  }
  sensitive = true
}
