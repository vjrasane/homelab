variable "pm_api_url" {
  type = string
}

variable "pm_api_token_id" {
  type = string
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "pm_node_name" {
  type = string
}

variable "lxc_control_node_memory" {
  type    = number
  default = 256
}

variable "lxc_control_node_cores" {
  type    = number
  default = 1
}

variable "lxc_control_node_storage" {
  type    = number
  default = 4
}

variable "lxc_work_node_memory" {
  type    = number
  default = 2048
}

variable "lxc_work_node_cores" {
  type    = number
  default = 4
}

variable "lxc_work_node_storage" {
  type    = number
  default = 32
}

variable "lxc_password" {
  type      = string
  sensitive = true
}

variable "lxc_storage" {
  type    = string
  default = "local-zfs"
}

variable "lxc_ostemplate" {
  type    = string
  # default = "local:vztmpl/ubuntu-24.10-standard_24.10-1_amd64.tar.zst"
  default = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
}

variable "lxc_default_gateway" {
  type    = string
  default = "192.168.1.1"
}

variable "lxc_ip_prefix" {
  type    = string
  default = "192.168.1"
}

data "tls_public_key" "ssh_public_key" {
  private_key_openssh = file("~/.ssh/id_rsa")
}
