
variable "state_passphrase" {
  description = "State encryption passphrase"
  type        = string
}

terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13.6"
    }
  }

  encryption {
    key_provider "pbkdf2" "passphrase" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "encrypt" {
      keys = key_provider.pbkdf2.passphrase
    }

    state {
      method = method.aes_gcm.encrypt
    }
  }
}

provider "bitwarden" {
  alias = "password_manager"
}
