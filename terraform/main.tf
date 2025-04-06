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

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

resource "tls_private_key" "lxc_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "proxmox_lxc" "control_node" {
  count        = 1
  hostname     = "lxc-control-node-${count.index + 1}"
  target_node  = var.pm_node_name
  vmid         = 2000 + count.index
  ostemplate   = var.lxc_ostemplate
  cores        = 1
  memory       = 1024
  password     = var.lxc_password
  unprivileged = false
  onboot       = true
  start        = false

  rootfs {
    storage = var.lxc_storage
    size    = "4G"
  }

  features {
    # nesting = true
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.lxc_ip_prefix}.${110 + count.index}/32"
    # ip = dchp
    # ip6    = "manual"
    gw = var.lxc_default_gateway
    # firewall = true
  }

  ssh_public_keys = tls_private_key.lxc_ssh_key.public_key_openssh
}

resource "proxmox_lxc" "work_node" {
  count        = 2
  hostname     = "lxc-work-node-${count.index + 1}"
  target_node  = var.pm_node_name
  vmid         = 1000 + count.index
  ostemplate   = var.lxc_ostemplate
  cores        = 2
  memory       = 2048
  password     = var.lxc_password
  unprivileged = false
  onboot       = true
  start        = false

  rootfs {
    storage = var.lxc_storage
    size    = "32G"
  }

  features {
    # nesting = true
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.lxc_ip_prefix}.${110 + count.index + length(proxmox_lxc.control_node)}/32"
    # ip6    = "manual"
    gw = var.lxc_default_gateway
    # firewall = true
  }

  ssh_public_keys = tls_private_key.lxc_ssh_key.public_key_openssh
}
resource "ansible_group" "k3s_cluster" {
  name     = "k3s_cluster"
  children = ["server", "agent"]
}
resource "ansible_host" "control_node" {
  count  = length(proxmox_lxc.control_node)
  name   = proxmox_lxc.control_node[count.index].hostname
  groups = ["server"]
  variables = {
    ansible_host                 = trimsuffix(proxmox_lxc.control_node[count.index].network[0].ip, "/32")
    ansible_user                 = "root"
    ansible_ssh_private_key_file = local_file.lxc_ssh_key.filename
    vmid = proxmox_lxc.control_node[count.index].vmid
  }
}

resource "ansible_host" "work_node" {
  count  = length(proxmox_lxc.work_node)
  name   = proxmox_lxc.work_node[count.index].hostname
  groups = ["agent"]
  variables = {
    ansible_host                 = trimsuffix(proxmox_lxc.work_node[count.index].network[0].ip, "/32")
    ansible_user                 = "root"
    ansible_ssh_private_key_file = local_file.lxc_ssh_key.filename
    vmid = proxmox_lxc.work_node[count.index].vmid
  }
}

resource "ansible_host" "proxmox_host" {
  name   = "proxmox_host"
  groups = ["proxmox"]
  variables = {
    ansible_host     = var.pm_host
    ansible_user     = var.pm_user
    ansible_ssh_pass = var.pm_password
  }
}

resource "local_file" "lxc_ssh_key" {
  content         = tls_private_key.lxc_ssh_key.private_key_pem
  filename        = "${path.module}/lxc_ssh_key.pem"
  file_permission = "0600"
}

output "lxc_ssh_key" {
  value     = tls_private_key.lxc_ssh_key
  sensitive = true
}
