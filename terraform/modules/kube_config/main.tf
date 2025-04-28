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

variable "k3s_server_hostname" {
  type = string
}

module "get_kube_config" {
  source = "../ssh_cmd"

  hostname        = var.hostname
  user            = var.user
  private_key_pem = var.private_key_pem
  command         = "cat /etc/rancher/k3s/k3s.yaml | sed 's|server: https://127.0.0.1:6443|server: https://${var.k3s_server_hostname}:6443|'"
}

output "config" {
  value     = module.get_kube_config.result
  sensitive = true
}
