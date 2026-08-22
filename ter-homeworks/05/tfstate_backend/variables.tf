### Provider and Authentication Variables
variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud Folder ID"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Default Availability Zone"
}

variable "service_account_key_file" {
  type        = string
  description = "Path to Service Account JSON key"
}

### Service Account Variables
variable "sa_name" {
  type        = string
  default     = "tf-state-manager"
  description = "Name for the state management service account"
}

variable "sa_description" {
  type        = string
  default     = "Service account for managing Terraform remote state"
  description = "Description for the service account"
}

variable "sa_role" {
  type        = string
  default     = "storage.admin"
  description = "IAM role assigned to the state service account"
}

### Bucket Configuration Variables
variable "bucket_prefix" {
  type        = string
  default     = "tfstate"
  description = "Prefix for unique S3 bucket name"
}

variable "bucket_max_size" {
  type        = number
  default     = 1073741824 # 1 GB
  description = "Maximum size of the S3 bucket in bytes"
}

variable "bucket_default_storage_class" {
  type        = string
  default     = "STANDARD"
  description = "Default storage class for the S3 bucket"
}

variable "bucket_versioning_enabled" {
  type        = bool
  default     = true
  description = "Enable versioning for tfstate bucket"
}

variable "random_suffix_length" {
  type        = number
  default     = 8
  description = "Length of the random suffix for the bucket name"
}

variable "iam_propagation_delay_seconds" {
  type        = number
  default     = 15
  description = "Wait time in seconds for cloud IAM policy and key propagation"
}

### Remote Backend Template Variables
variable "tfstate_key" {
  type        = string
  default     = "terraform.tfstate"
  description = "State file key in S3 bucket"
}

variable "s3_endpoint" {
  type        = string
  default     = "https://storage.yandexcloud.net"
  description = "Yandex Object Storage endpoint URL"
}

variable "s3_region" {
  type        = string
  default     = "ru-central1"
  description = "S3 region name"
}

variable "terraform_required_version" {
  type        = string
  default     = ">= 1.15.0"
  description = "Terraform version constraint for generated backend configuration"
}
