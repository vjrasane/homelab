terraform {
  required_providers {
    ansible = {
      source = "ansible/ansible"
    }
  }
}

resource "local_file" "lxc_ssh_key" {
  content         = var.lxc_private_key_pem
  filename        = "${path.module}/.ssh/${var.lxc_ip}.pem"
  file_permission = "0600"
}

resource "ansible_playbook" "install_k3s" {
  name       = var.lxc_ip
  playbook   = "${path.module}/ansible/install_k3s_master.yml"
  replayable = false
  extra_vars = {
    ansible_user                 = var.lxc_user
    ansible_ssh_private_key_file = local_file.lxc_ssh_key.filename
    ansible_python_interpreter   = "/usr/bin/python3"
    k3s_vip                      = var.k3s_vip
  }
}

module "k3s_token" {
  source = "../ssh_cmd"

  hostname        = var.lxc_ip
  user            = var.lxc_user
  private_key_pem = var.lxc_private_key_pem
  command         = "cat /var/lib/rancher/k3s/server/token"

  depends_on = [ansible_playbook.install_k3s]
}

module "kube_config" {
  source = "../kube_config"

  hostname        = var.lxc_ip
  user            = var.lxc_user
  private_key_pem = var.lxc_private_key_pem

  depends_on = [ansible_playbook.install_k3s]
}


# data "external" "k3s_token" {
#   program = [
#     "bash", "${path.module}/scripts/get_k3s_token.sh"
#   ]

#   query = {
#     hostname         = var.lxc_ip,
#     user             = var.lxc_user,
#     private_key_file = local_file.lxc_ssh_key.filename,
#   }

#   depends_on = [ansible_playbook.install_k3s]
# }

# data "external" "kube_config" {
#   program = [
#     "bash", "${path.module}/scripts/get_kube_config.sh"
#   ]

#   query = {
#     hostname         = var.lxc_ip,
#     user             = var.lxc_user,
#     private_key_file = local_file.lxc_ssh_key.filename,
#     # k3s_vip          = var.k3s_vip
#   }

#   depends_on = [ansible_playbook.install_k3s]
# }

output "k3s_token" {
  value     = module.k3s_token.result
  sensitive = true
}

output "kube_config" {
  value     = module.kube_config.config
  sensitive = true
}

# output "client_certificate" {
#   value = module.kube_config.client_certificate
# }

# output "cluster_ca_certificate" {
#   value = module.kube_config.cluster_ca_certificate
# }

# output "client_key" {
#   value     = module.kube_config.client_key
#   sensitive = true
# }

output "k3s_master_ip" {
  value = var.lxc_ip
}
