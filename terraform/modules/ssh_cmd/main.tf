variable "hostname" {
  type = string
}

variable "user" {
  type    = string
  default = "root"
}

variable "private_key_pem" {
  type      = string
  sensitive = true
}

variable "command" {
  type = string
}

resource "local_file" "private_key_file" {
  content         = var.private_key_pem
  filename        = "${path.module}/.ssh/${var.hostname}.pem"
  file_permission = "0600"
}

data "external" "ssh_cmd" {
  program = [
    "bash", "${path.module}/scripts/run_ssh_cmd.sh"
  ]

  query = {
    hostname         = var.hostname,
    user             = var.user,
    private_key_file = local_file.private_key_file.filename,
    command          = var.command
  }
}

output "result" {
  value = data.external.ssh_cmd.result["result"]
}

output "result_json" {
  value = data.external.ssh_cmd.result
}
