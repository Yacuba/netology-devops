terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.0.0"
    }
  }
}

# Configure the HashiCorp Vault Provider
provider "vault" {
  address         = "http://127.0.0.1:8200"
  skip_tls_verify = true
  token           = "education"
}
