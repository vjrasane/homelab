
locals {
  proxmox_ip = "192.168.1.101"
  # master_node_ip = "192.168.1.80"
  # control_node_ips = [
  #   "192.168.2.111",
  #   "192.168.2.112",
  # ]

  # worker_node_ips = [
  #   "192.168.2.120",
  #   "192.168.2.121",
  # ]

  subnet_mask = "/24"

  lxc_default_gateway = "192.168.1.1"

  lxc_ostemplate = "local:vztmpl/ubuntu-24.10-standard_24.10-1_amd64.tar.zst"

  lxc_password = "password"
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

resource "local_file" "lxc_ssh_key" {
  content         = tls_private_key.lxc_ssh_key.private_key_pem
  filename        = "${path.module}/../lxc_ssh_key.pem"
  file_permission = "0600"
}

resource "random_password" "lxc_password" {
  length  = 16
  special = true
}

resource "proxmox_lxc" "master_node" {
  hostname    = "lxc-k3s-master-node"
  target_node = var.pm_node_name
  vmid        = 1000
  ostemplate  = local.lxc_ostemplate
  cores       = 1
  memory      = 1024
  # password     = random_password.lxc_password.result
  password     = local.lxc_password
  unprivileged = false
  onboot       = true
  start        = false

  rootfs {
    storage = var.lxc_storage
    size    = "4G"
  }

  features {
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    gw     = local.lxc_default_gateway
  }

  ssh_public_keys = tls_private_key.lxc_ssh_key.public_key_openssh

  # connection {
  #   host        = trimsuffix(self.network[0].ip, "${local.subnet_mask}")
  #   private_key = tls_private_key.lxc_ssh_key.private_key_openssh
  # }

  # provisioner "file" {
  #   source      = "${path.module}/files/conf-kmsg.service"
  #   destination = "/etc/systemd/system/conf-kmsg.service"
  # }

  # provisioner "file" {
  #   source      = "${path.module}/files/conf-kmsg.sh"
  #   destination = "/usr/local/bin/conf-kmsg.sh"
  # }

  # provisioner "local-exec" {
  #   command = <<-EOC
  #     cat <<-EOF >> /etc/pve/lxc/${self.vmid}.conf
  #       lxc.apparmor.profile: unconfined
  #       lxc.cgroup.devices.allow: a
  #       lxc.cap.drop: 
  #       lxc.mount.auto: "proc:rw sys:rw"
  #     EOF
  #     pct reboot ${self.vmid}
  #   EOC

  #   connection {
  #     host     = local.proxmox_ip
  #     user     = var.pm_user
  #     password = var.pm_password
  #   }
  # }
}

resource "null_resource" "fetch_master_node_ip" {
  connection {
    host     = local.proxmox_ip
    user     = var.pm_user
    password = var.pm_password
  }

  provisioner "file" {
    source      = "${path.module}/scripts/patch_lxc_config.sh"
    destination = "/tmp/patch_lxc_config.sh"
  }

  provisioner "file" {
    source      = "${path.module}/files"
    destination = "/tmp/files"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/patch_lxc_config.sh",
      "/tmp/patch_lxc_config.sh ${proxmox_lxc.master_node.vmid}",
      "rm -f /tmp/patch_lxc_config.sh",
    ]
  }

  provisioner "local-exec" {
    command = <<-EOC
      sshpass -p '${var.pm_password}' ssh ${var.pm_user}@${local.proxmox_ip} 'lxc-info -n ${proxmox_lxc.master_node.vmid} -iH' > /tmp/${proxmox_lxc.master_node.vmid}.ip
    EOC
  }
}

# resource "null_resource" "configure_master_node" {
#   depends_on = [null_resource.fetch_master_node_ip]

#   connection {
#     type = "ssh"
#     user = "root"
#     # password = local.lxc_password
#     host        = file("/tmp/${proxmox_lxc.master_node.vmid}.ip")
#     private_key = file(local_file.lxc_ssh_key.filename) 
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "echo 'Hello, world!'",
#       "echo 'This is a test.'",
#     ]
#   }

#   # provisioner "file" {
#   #   source      = "${path.module}/files/conf-kmsg.service"
#   #   destination = "/etc/systemd/system/conf-kmsg.service"
#   # }

#   # provisioner "file" {
#   #   source      = "${path.module}/files/conf-kmsg.sh"
#   #   destination = "/usr/local/bin/conf-kmsg.sh"
#   # }
# }
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
