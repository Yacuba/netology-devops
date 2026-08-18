# Read existing secret from Vault
data "vault_generic_secret" "vault_example" {
  path = "secret/example"
}

# Write a new secret into Vault
resource "vault_kv_secret_v2" "terraform_secret" {
  mount               = "secret"
  name                = "terraform_secret"
  delete_all_versions = true
  data_json = jsonencode({
    db_password = "SuperSecretPassword2026!"
    api_token   = "netology-token-xyz"
  })
}
