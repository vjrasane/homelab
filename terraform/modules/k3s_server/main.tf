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
  playbook   = "${path.module}/ansible/install_k3s_server.yml"
  replayable = false
  extra_vars = {
    ansible_user                 = var.lxc_user
    ansible_ssh_private_key_file = local_file.lxc_ssh_key.filename
    ansible_python_interpreter   = "/usr/bin/python3"
    k3s_vip                      = var.k3s_vip
    k3s_token                    = var.k3s_token
  }
}

