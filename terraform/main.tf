terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}

resource "proxmox_lxc" "control-node" {
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

  ssh_public_keys = data.tls_public_key.ssh_public_key.public_key_openssh
}

resource "proxmox_lxc" "work-node" {
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

  ssh_public_keys = data.tls_public_key.ssh_public_key.public_key_openssh
}
