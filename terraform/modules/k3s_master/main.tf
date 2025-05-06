terraform {
  required_providers {
    ansible = {
      source = "ansible/ansible"
    }
  }
}

resource "ansible_playbook" "install_k3s" {
  name       = var.lxc_ip
  playbook   = "${path.module}/ansible/install_k3s_master.yml"
  replayable = false
  extra_vars = {
    ansible_user                 = var.lxc_user
    ansible_ssh_private_key_file = var.lxc_private_key_file
    ansible_python_interpreter   = "/usr/bin/python3"
    k3s_vip                      = var.k3s_vip
    k3s_metallb_ip_pool          = var.k3s_metallb_ip_pool
  }
}

module "k3s_token" {
  source = "../ssh_cmd"

  hostname        = var.lxc_ip
  user            = var.lxc_user
  private_key_file = var.lxc_private_key_file
  command         = "cat /var/lib/rancher/k3s/server/token"

  depends_on = [ansible_playbook.install_k3s]
}

module "kube_config" {
  source = "../kube_config"

  hostname        = var.lxc_ip
  user            = var.lxc_user
  private_key_file = var.lxc_private_key_file

  depends_on = [ansible_playbook.install_k3s]
}

output "k3s_token" {
  value     = module.k3s_token.result
  sensitive = true
}

output "kube_config" {
  value     = module.kube_config.config
  sensitive = true
}

output "k3s_master_ip" {
  value = var.lxc_ip
}
