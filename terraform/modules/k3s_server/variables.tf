
variable "lxc_ip" {
  type = string
}

variable "k3s_vip" {
  type = string
}

variable "k3s_token" {
  type = string
}

variable "lxc_user" {
  type    = string
  default = "root"
}

variable "lxc_private_key_file" {
  type      = string
}
