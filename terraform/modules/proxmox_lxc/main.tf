
terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }

    ansible = {
      source = "ansible/ansible"
    }
  }
}

locals {
  lxc_ostemplate = "local:vztmpl/ubuntu-24.10-standard_24.10-1_amd64.tar.zst"
  lxc_storage    = "local-zfs"
}

resource "random_password" "lxc_password" {
  length  = 16
  special = true
}

resource "random_pet" "lxc_name" {
  keepers = {
    lxc_name = var.lxc_name
  }
}

resource "proxmox_lxc" "ct" {
  hostname     = var.lxc_name == "" ? "lxc-${random_pet.lxc_name.id}" : var.lxc_name
  target_node  = var.pm_node_name
  vmid         = var.lxc_vmid
  ostemplate   = local.lxc_ostemplate
  cores        = var.lxc_cores
  memory       = var.lxc_memory
  password     = random_password.lxc_password.result
  unprivileged = false
  onboot       = true
  start        = true

  rootfs {
    storage = local.lxc_storage
    size    = "${var.lxc_storage_size}G"
  }

  features {
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.lxc_ip}${var.subnet_mask}"
    gw     = var.lxc_default_gateway
  }

  ssh_public_keys = var.public_key_openssh

  connection {
    host     = var.pm_ip
    user     = var.pm_user
    password = var.pm_password
  }

  provisioner "remote-exec" {
    inline = [
      "rm -f /tmp/patch_lxc_config.sh || true",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/scripts/patch_lxc_config.sh"
    destination = "/tmp/patch_lxc_config.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/patch_lxc_config.sh",
      "/tmp/patch_lxc_config.sh ${self.vmid}",
      "rm -f /tmp/patch_lxc_config.sh",
    ]
  }
}

resource "ansible_playbook" "configure_lxc" {
  name       = var.lxc_ip
  playbook   = "${path.module}/ansible/configure_lxc.yml"
  replayable = false
  extra_vars = {
    ansible_user                 = "root"
    ansible_ssh_private_key_file = var.lxc_private_key_file
    ansible_python_interpreter   = "/usr/bin/python3"
  }
  
  timeouts {
    create = "1m"
  }

  depends_on = [proxmox_lxc.ct]
}

output "lxc_password" {
  value     = random_password.lxc_password.result
  sensitive = true
}

output "lxc_ip" {
  value = var.lxc_ip
}

output "lxc_vmid" {
  value = proxmox_lxc.ct.vmid
}
