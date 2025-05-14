variable "state_passphrase" {
  description = "State encryption passphrase"
  type        = string
}

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
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

  remote_state_data_sources {
    default {
      method = method.aes_gcm.encrypt
    }
  }
}
