# Random unique suffix generation
resource "random_string" "bucket_suffix" {
  length  = var.random_suffix_length
  special = false
  upper   = false

  keepers = {
    folder_id = var.folder_id
  }  
}

# Service account creation
resource "yandex_iam_service_account" "sa" {
  name        = var.sa_name
  description = var.sa_description
}

# Assign IAM role to service account on target folder
resource "yandex_resourcemanager_folder_iam_member" "storage_admin" {
  folder_id = var.folder_id
  role      = var.sa_role
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# Static access key generation for S3 backend authentication
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for S3 remote state: ${var.sa_name}"
}

# Automatic delay for IAM propagation
resource "time_sleep" "wait_for_iam_propagation" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.storage_admin,
    yandex_iam_service_account_static_access_key.sa_static_key
  ]

  create_duration = "${var.iam_propagation_delay_seconds}s"
}

# S3 Bucket creation with versioning
resource "yandex_storage_bucket" "tfstate" {
  bucket                = "${var.bucket_prefix}-${random_string.bucket_suffix.result}"
  access_key            = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  max_size              = var.bucket_max_size
  default_storage_class = var.bucket_default_storage_class

  versioning {
    enabled = var.bucket_versioning_enabled
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.storage_admin
  ]
}
