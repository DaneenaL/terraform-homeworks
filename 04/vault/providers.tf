terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
  }
  required_version = ">= 1.12.0"
}

provider "vault" {
  address         = var.vault_address
  skip_tls_verify = true
  token           = var.vault_token
}
