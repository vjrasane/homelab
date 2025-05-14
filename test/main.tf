terraform {
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13.6"
    }

    ansible = {
      source = "ansible/ansible"
    }
  }

  encryption {
    key_provider "pbkdf2" "passphrase" {
      passphrase = "<default>"
    }

    method "aes_gcm" "encrypt" {
      keys = key_provider.pbkdf2.passphrase
    }

    state {
      enforced = true
      method   = method.aes_gcm.encrypt
    }

    plan {
      enforced = true
      method   = method.aes_gcm.encrypt
    }
  }

  backend "s3" {
    region    = "eu-central-003"
    endpoint = "s3.eu-central-003.backblazeb2.com"
    bucket    = "karkkinet-terraform-state"
    key       = "test.tfstate"

    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    skip_credentials_validation = true
  }
}

# data "bitwarden_item_login" "pm_login" {
#   provider = bitwarden.password_manager
#   search   = "proxmox login"
# }

data "bitwarden_secret" "proxmox_password" {
  key      = "pm_password"
}

# locals {
#   fields            = data.bitwarden_item_login.pm_login.field
#   pm_node_name      = local.fields[index(local.fields.*.name, "Node name")]
#   pm_api_key_secret = local.fields[index(local.fields.*.name, "API key secret")]
# }

output "proxmox_password" {
  value     = data.bitwarden_secret.proxmox_password.value
  sensitive = true
}

# output "pm_node_name" {
#   value     = local.pm_node_name.text
#   sensitive = true
# }

# output "pm_api_key_secret" {
#   value     = local.pm_api_key_secret.hidden
#   sensitive = true
# }

# output "pm_login" {
#   value     = data.bitwarden_item_login.pm_login.field
#   sensitive = true
# }


