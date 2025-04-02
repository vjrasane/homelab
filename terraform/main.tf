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
  hostname     = "LXC-control-node-${count.index + 1}"
  target_node  = var.pm_node_name
  vmid         = 2000 + count.index
  ostemplate   = var.lxc_ostemplate
  cores        = var.lxc_control_node_cores
  memory       = var.lxc_control_node_memory
  swap         = 256
  password     = var.lxc_password
  unprivileged = true
  onboot       = true
  start        = true

  rootfs {
    storage = var.lxc_storage
    size    = "${var.lxc_control_node_storage}G"
  }

  features {
    nesting = true
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.lxc_ip_prefix}.${110 + count.index}/32"
    # ip = dchp
    # ip6    = "manual"
    gw = var.lxc_default_gateway
  }

  ssh_public_keys = tls_private_key.lxc_ssh_key.public_key_openssh
}

resource "proxmox_lxc" "work_node" {
  count        = 2
  hostname     = "LXC-work-node-${count.index + 1}"
  target_node  = var.pm_node_name
  vmid         = 1000 + count.index
  ostemplate   = var.lxc_ostemplate
  cores        = var.lxc_work_node_cores
  memory       = var.lxc_work_node_memory
  swap         = 512
  password     = var.lxc_password
  unprivileged = true
  onboot       = true
  start        = true

  rootfs {
    storage = var.lxc_storage
    size    = "${var.lxc_work_node_storage}G"
  }

  features {
    nesting = true
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.lxc_ip_prefix}.${120 + count.index}/32"
    # ip6    = "manual"
    gw = var.lxc_default_gateway
  }

  ssh_public_keys = tls_private_key.lxc_ssh_key.public_key_openssh
}

resource "ansible_host" "control_node" {
  count  = length(proxmox_lxc.control_node)
  name   = proxmox_lxc.control_node[count.index].hostname
  groups = ["control_node"]
  variables = {
    ansible_host                 = trimsuffix(proxmox_lxc.control_node[count.index].network[0].ip, "/32")
    ansible_user                 = "root"
    ansible_ssh_private_key_file = local_file.lxc_ssh_key.filename
  }
}

resource "ansible_host" "work_node" {
  count  = length(proxmox_lxc.work_node)
  name   = proxmox_lxc.work_node[count.index].hostname
  groups = ["work_node"]
  variables = {
    ansible_host                 = trimsuffix(proxmox_lxc.work_node[count.index].network[0].ip, "/32")
    ansible_user                 = "root"
    ansible_ssh_private_key_file = local_file.lxc_ssh_key.filename
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
