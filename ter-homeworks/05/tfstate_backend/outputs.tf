output "bucket_name" {
  description = "The name of the created S3 bucket for tfstate"
  value       = yandex_storage_bucket.tfstate.bucket
}

output "access_key_id" {
  description = "Static Access Key ID for S3 backend"
  value       = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  sensitive   = true
}

output "secret_key" {
  description = "Secret Access Key for S3 backend"
  value       = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  sensitive   = true
}

output "backend_config_example" {
  description = "Dynamic backend configuration snippet for consumption in root modules"
  value       = <<-EOT
    terraform {
      required_version = "${var.terraform_required_version}"

      backend "s3" {
        bucket  = "${yandex_storage_bucket.tfstate.bucket}"
        key     = "${var.tfstate_key}"
        region  = "${var.s3_region}"

        # Native state locking mechanism
        use_lockfile = true

        endpoints = {
          s3 = "${var.s3_endpoint}"
        }

        skip_region_validation      = true
        skip_credentials_validation = true
        skip_requesting_account_id  = true
        skip_s3_checksum            = true
      }
    }
  EOT
}
