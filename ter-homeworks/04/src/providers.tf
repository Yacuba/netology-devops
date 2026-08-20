terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">= 0.130.0"
    }
    template = {
      source = "hashicorp/template"
      version = ">= 2.2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }    
  }
  required_version = "~>1.15.0"

  backend "s3" {
    bucket  = "yacuba-tfstate-bucket-2026"
    key     = "terraform.tfstate"
    region  = "ru-central1"

    # Встроенный механизм блокировок (Terraform >= 1.6)
    use_lockfile = true

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  service_account_key_file = file(var.service_account_key_file)
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
}

provider "aws" {
  region                      = "ru-central1"
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_key"
  secret_key                  = "mock_key"
}
