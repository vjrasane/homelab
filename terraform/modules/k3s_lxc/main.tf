terraform {
  required_providers {
    ansible = {
      source = "ansible/ansible"
    }
  }
}

variable "lxc_ip" {
  description = "IP address of the LXC container"
  type        = string
}

variable "lxc_private_key_file" {
  description = "Path to the private key file for SSH access to the LXC container"
  type        = string
}

module "prepare_k3s_lxc" {
  source = "../ansible_playbook"

  hostname   = var.lxc_ip
  playbook   = "${path.module}/prepare_k3s_lxc.yml"
  replayable = false

  extra_vars = {
    ansible_user                 = "root"
    ansible_ssh_private_key_file = var.lxc_private_key_file
    ansible_python_interpreter   = "/usr/bin/python3"
  }
}

resource "ansible_playbook" "prepare" {
  name       = var.lxc_ip
  playbook   = "${path.module}/ansible/prepare_k3s_lxc.yml"
  replayable = false
  extra_vars = {
    ansible_user                 = "root"
    ansible_ssh_private_key_file = var.lxc_private_key_file
    ansible_python_interpreter   = "/usr/bin/python3"
  }

  timeouts {
    create = "1m"
  }
}
