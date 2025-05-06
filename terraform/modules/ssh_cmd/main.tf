variable "hostname" {
  type = string
}

variable "user" {
  type    = string
  default = "root"
}

variable "private_key_file" {
  type      = string
}

variable "command" {
  type = string
}

data "external" "ssh_cmd" {
  program = [
    "bash", "${path.module}/scripts/run_ssh_cmd.sh"
  ]

  query = {
    hostname         = var.hostname,
    user             = var.user,
    private_key_file = var.private_key_file,
    command          = var.command
  }
}

output "result" {
  value = data.external.ssh_cmd.result["result"]
}

output "result_json" {
  value = data.external.ssh_cmd.result
}
