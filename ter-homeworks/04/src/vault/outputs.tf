# Output data retrieved from the existing secret
output "vault_example" {
  value       = nonsensitive(data.vault_generic_secret.vault_example.data)
  description = "Data retrieved from secret/example"
}

# Output the name of the secret created by Terraform
output "created_terraform_secret_name" {
  value       = vault_kv_secret_v2.terraform_secret.name
  description = "Name of the newly created KV v2 secret"
}
