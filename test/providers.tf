# variable "bitwarden_client_id" {
#   description = "Bitwarden client ID"
#   type        = string
#   sensitive   = true
# }

# variable "bitwarden_client_secret" {
#   description = "Bitwarden client secret"
#   type        = string
#   sensitive   = true
# }

# variable "bitwarden_master_password" {
#   description = "Bitwarden master password"
#   type        = string
#   sensitive   = true
# }

# variable "bitwarden_access_token" {
#   description = "Bitwarden access token"
#   type        = string
#   sensitive   = true
# }

# data "sops_file" "secrets" {
#   source_file = "${path.module}/bitwarden.secrets.yaml"
# }

# locals {
#   secrets                   = data.sops_file.secrets.data
#   bitwarden_client_id       = local.secrets.bitwarden_client_id
#   bitwarden_client_secret   = local.secrets.bitwarden_client_secret
#   bitwarden_master_password = local.secrets.bitwarden_master_password
#   bitwarden_access_token    = local.secrets.bitwarden_access_token
# }

# provider "bitwarden" {
#   alias           = "password_manager"
#   client_id       = local.bitwarden_client_id
#   client_secret   = local.bitwarden_client_secret
#   master_password = local.bitwarden_master_password
# }

provider "bitwarden" {
  experimental {
    embedded_client = true
  }
}
