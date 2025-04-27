
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

resource "tls_private_key" "lxc_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
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

  ssh_public_keys = tls_private_key.lxc_ssh_key.public_key_openssh

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

resource "local_file" "lxc_ssh_key" {
  content         = tls_private_key.lxc_ssh_key.private_key_pem
  filename        = "${path.module}/.ssh/${proxmox_lxc.ct.vmid}-${proxmox_lxc.ct.hostname}.pem"
  file_permission = "0600"
}

resource "ansible_playbook" "configure_lxc" {
  name       = var.lxc_ip
  playbook   = "${path.module}/ansible/configure_lxc.yml"
  replayable = false
  extra_vars = {
    ansible_user                 = "root"
    ansible_ssh_private_key_file = local_file.lxc_ssh_key.filename
    ansible_python_interpreter   = "/usr/bin/python3"
  }

  depends_on = [proxmox_lxc.ct]
}

output "lxc_password" {
  value     = random_password.lxc_password.result
  sensitive = true
}

output "lxc_private_key_pem" {
  value     = tls_private_key.lxc_ssh_key.private_key_pem
  sensitive = true
}

output "lxc_ip" {
  value = var.lxc_ip
}

output "lxc_vmid" {
  value = proxmox_lxc.ct.vmid
}

# resource "proxmox_lxc" "control_node" {
#   count        = length(local.control_node_ips)
#   hostname     = "lxc-k3s-control-node-${count.index + 1}"
#   target_node  = var.pm_node_name
#   vmid         = 2000 + count.index
#   ostemplate   = var.lxc_ostemplate
#   cores        = 1
#   memory       = 1024
#   password     = random_password.lxc_password.result
#   unprivileged = false
#   onboot       = true
#   start        = true

#   rootfs {
#     storage = var.lxc_storage
#     size    = "4G"
#   }

#   features {
#   }

#   network {
#     name   = "eth0"
#     bridge = "vmbr0"
#     ip     = "${var.lxc_ip_prefix}.${190 + count.index}/32"
#     gw     = var.lxc_default_gateway
#   }

#   ssh_public_keys = tls_private_key.lxc_ssh_key.public_key_openssh
# }

# resource "proxmox_lxc" "work_node" {
#   count        = 2
#   hostname     = "lxc-work-node-${count.index + 1}"
#   target_node  = var.pm_node_name
#   vmid         = 1000 + count.index
#   ostemplate   = var.lxc_ostemplate
#   cores        = 2
#   memory       = 2048
#   password     = random_password.lxc_password.result
#   unprivileged = false
#   onboot       = true
#   start        = true

#   rootfs {
#     storage = var.lxc_storage
#     size    = "32G"
#   }

#   features {
#     # nesting = true
#   }

#   network {
#     name   = "eth0"
#     bridge = "vmbr0"
#     ip     = "${var.lxc_ip_prefix}.${190 + count.index + length(proxmox_lxc.control_node)}/32"
#     # ip6    = "manual"
#     gw = var.lxc_default_gateway
#     # firewall = true
#   }

#   ssh_public_keys = tls_private_key.lxc_ssh_key.public_key_openssh

#   connection {
#     type = "ssh"
#     user = "root"

#     host        = trimsuffix(self.network[0].ip, "/32")
#     private_key = tls_private_key.lxc_ssh_key.public_key_pem
#   }

#   provisioner "file" {
#     source      = "${path.module}/files/conf-kmsg.service"
#     destination = "/etc/systemd/system/conf-kmsg.service"
#   }

#   provisioner "file" {
#     source      = "${path.module}/files/conf-kmsg.sh"
#     destination = "/usr/local/bin/conf-kmsg.sh"
#   }
# }
