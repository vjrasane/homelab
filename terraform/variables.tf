variable "pm_api_token_name" {
  type    = string
  default = "terraform"
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "pm_api_user" {
  type    = string
  default = "terraform@pam"
}

variable "pm_node_name" {
  type = string
}

variable "pm_host" {
  type    = string
  default = "192.168.1.101"
}

variable "pm_user" {
  type    = string
  default = "root"
}

variable "pm_password" {
  type      = string
  sensitive = true
}

variable "lxc_storage" {
  type    = string
  default = "local-zfs"
}

variable "lxc_ostemplate" {
  type = string
  default = "local:vztmpl/ubuntu-24.10-standard_24.10-1_amd64.tar.zst"
  # default = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
}

variable "lxc_default_gateway" {
  type    = string
  default = "192.168.1.1"
}

variable "lxc_ip_prefix" {
  type    = string
  default = "192.168.1"
}

variable "k3s_vip" {
  type   = string 
  default = "192.168.1.102"
}
