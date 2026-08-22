terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    template = {
      source = "hashicorp/template"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }    
  }
  required_version = "~>1.15.0"
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
