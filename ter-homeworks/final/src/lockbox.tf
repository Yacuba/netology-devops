# Generate secure random password for database
resource "random_password" "mysql_password" {
  length           = var.db_password_params.length
  special          = var.db_password_params.special
  override_special = var.db_password_params.override_special
}

# Yandex Lockbox Secret
resource "yandex_lockbox_secret" "mysql_secret" {
  name        = local.lockbox_name
  description = "MySQL database credentials for ${local.name_prefix}"
  folder_id   = var.folder_id
}

# Lockbox Secret Version storing the generated password
resource "yandex_lockbox_secret_version" "mysql_password_version" {
  secret_id = yandex_lockbox_secret.mysql_secret.id
  entries {
    key        = var.lockbox_secret_key
    text_value = random_password.mysql_password.result
  }
}

# Data source to read secret payload from Lockbox
data "yandex_lockbox_secret_version" "mysql_password_data" {
  secret_id  = yandex_lockbox_secret.mysql_secret.id
  version_id = yandex_lockbox_secret_version.mysql_password_version.id
}
