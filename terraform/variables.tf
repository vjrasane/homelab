variable "pm_ip" {
  type = string  
  default = "192.168.1.101"
}

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

variable "k3s_vip" {
  type   = string 
  default = "192.168.1.102"
}

variable "lxc_default_gateway" {
  type = string
  default = "192.168.1.1"
}
