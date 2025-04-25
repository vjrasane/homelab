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


# resource "ansible_group" "k3s_cluster" {
#   name     = "k3s_cluster"
#   children = ["server", "agent"]
# }

# resource "ansible_host" "control_node" {
#   count  = length(proxmox_lxc.control_node)
#   name   = proxmox_lxc.control_node[count.index].hostname
#   groups = ["server"]
#   variables = {
#     ansible_host                 = trimsuffix(proxmox_lxc.control_node[count.index].network[0].ip, "/32")
#     ansible_user                 = "root"
#     ansible_ssh_private_key_file = "${path.module}/${local_file.lxc_ssh_key.filename}"
#     ansible_python_interpreter   = "/usr/bin/python3"
#     vmid                         = proxmox_lxc.control_node[count.index].vmid
#   }
# }

# resource "ansible_host" "work_node" {
#   count  = length(proxmox_lxc.work_node)
#   name   = proxmox_lxc.work_node[count.index].hostname
#   groups = ["agent"]
#   variables = {
#     ansible_host                 = trimsuffix(proxmox_lxc.work_node[count.index].network[0].ip, "/32")
#     ansible_user                 = "root"
#     ansible_ssh_private_key_file = "${path.module}/${local_file.lxc_ssh_key.filename}"
#     ansible_python_interpreter   = "/usr/bin/python3"
#     vmid                         = proxmox_lxc.work_node[count.index].vmid
#   }
# }

# resource "ansible_host" "proxmox_host" {
#   name   = "proxmox_host"
#   groups = ["proxmox"]
#   variables = {
#     ansible_host     = var.pm_host
#     ansible_user     = var.pm_user
#     ansible_ssh_pass = var.pm_password
#   }
# }

# resource "local_file" "lxc_ssh_key" {
#   content         = tls_private_key.lxc_ssh_key.private_key_pem
#   filename        = "${path.module}/../lxc_ssh_key.pem"
#   file_permission = "0600"
# }

# resource "local_file" "terraform_vars" {
#   content  = <<EOF
#   pm_host: ${var.pm_host}
#   pm_api_user: ${var.pm_api_user}
#   pm_api_token_name: ${var.pm_api_token_name}
#   pm_api_token_secret: '${var.pm_api_token_secret}'
#   lxc_ssh_key_file: ${local_file.lxc_ssh_key.filename}
#   k3s_vip: ${var.k3s_vip}
#   EOF
#   filename = "${path.module}/../terraform_vars.yml"
# }

# output "lxc_ssh_key" {
#   value     = tls_private_key.lxc_ssh_key
#   sensitive = true
# }

# output "lxc_password" {
#   value     = random_password.lxc_password.result
#   sensitive = true
# }
