
locals {
  proxmox_ip     = "192.168.1.101"
  master_node_ip = "192.168.1.190"
  control_node_ips = [
    "192.168.1.191",
    "192.168.1.192",
  ]

  worker_node_ips = [
    "192.168.1.200",
    "192.168.1.201",
  ]

  lxc_default_gateway = "192.168.1.1"
}

provider "proxmox" {
  pm_api_url          = "http://${local.proxmox_ip}:8006/api2/json"
  pm_api_token_id     = "${var.pm_api_user}!${var.pm_api_token_name}"
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

resource "tls_private_key" "lxc_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "lxc_password" {
  length  = 16
  special = true
}

resource "proxmox_lxc" "master_node" {
  hostname     = "lxc-k3s-master-node"
  target_node  = var.pm_node_name
  vmid         = 1000
  ostemplate   = var.lxc_ostemplate
  cores        = 1
  memory       = 1024
  password     = random_password.lxc_password.result
  unprivileged = false
  onboot       = true
  start        = true

  rootfs {
    storage = var.lxc_storage
    size    = "4G"
  }

  features {
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${local.master_node_ip}/32"
    gw     = local.lxc_default_gateway
  }

  ssh_public_keys = tls_private_key.lxc_ssh_key.public_key_openssh

  connection {
    host        = trimsuffix(self.network[0].ip, "/32")
    private_key = tls_private_key.lxc_ssh_key.private_key_openssh
  }

  provisioner "file" {
    source      = "${path.module}/files/conf-kmsg.service"
    destination = "/etc/systemd/system/conf-kmsg.service"
  }

  provisioner "file" {
    source      = "${path.module}/files/conf-kmsg.sh"
    destination = "/usr/local/bin/conf-kmsg.sh"
  }

  provisioner "local-exec" {
    command = <<-EOC
      cat <<-EOF >> /etc/pve/lxc/${self.vmid}.conf
        lxc.apparmor.profile: unconfined
        lxc.cgroup.devices.allow: a
        lxc.cap.drop: 
        lxc.mount.auto: "proc:rw sys:rw"
      EOF
      pct reboot ${self.vmid}
    EOC

    connection {
      host     = local.proxmox_ip
      user     = var.pm_user
      password = var.pm_password
    }
  }
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
