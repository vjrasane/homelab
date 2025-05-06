terraform {
  required_providers {
    ansible = {
      source = "ansible/ansible"
    }
  }
}

resource "ansible_playbook" "install_k3s" {
  name       = var.lxc_ip
  playbook   = "${path.module}/ansible/install_k3s_server.yml"
  replayable = false
  extra_vars = {
    ansible_user                 = var.lxc_user
    ansible_ssh_private_key_file = var.lxc_private_key_file
    ansible_python_interpreter   = "/usr/bin/python3"
    k3s_vip                      = var.k3s_vip
    k3s_token                    = var.k3s_token
  }
}

