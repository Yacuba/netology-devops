###cloud vars
# variable "token" {
#   type        = string
#   description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
# }

variable "service_account_key_file" {
  type        = string
  description = "Path to service account key file"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network&subnet name"
}

### OS and SSH variables
variable "vm_web_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Compute image family for web VM"
}

# variable "ssh_public_key_path" {
#   type        = string
#   description = "Path to public SSH key"
# }

variable "ssh_user" {
  type        = string
  default     = "ubuntu"
  description = "Default SSH user"
}

variable "serial_port_enable" {
  type        = number
  default     = 1
  description = "Enable serial console"
}

### Count VMs variables
variable "web_vm_name_prefix" {
  type        = string
  default     = "web"
  description = "Prefix for web instances created via count loop"
}

variable "web_vm_count" {
  type        = number
  default     = 2
  description = "Number of web instances"
}

variable "web_vm_resources" {
  type = object({
    platform_id   = string
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
    preemptible   = bool
    nat           = bool
  })
  default = {
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 1
    core_fraction = 20
    disk_size     = 10
    preemptible   = true
    nat           = true
  }
  description = "Hardware specifications for web instances"
}

### for_each VMs variables
variable "each_vm" {
  type = list(object({
    vm_name       = string
    cpu           = number
    ram           = number
    disk_volume   = number
    core_fraction = number
    platform_id   = string
    preemptible   = bool
    nat           = bool
  }))
  default = [
    {
      vm_name       = "main"
      cpu           = 4
      ram           = 4
      disk_volume   = 15
      core_fraction = 20
      platform_id   = "standard-v3"
      preemptible   = true
      nat           = true
    },
    {
      vm_name       = "replica"
      cpu           = 2
      ram           = 2
      disk_volume   = 10
      core_fraction = 20
      platform_id   = "standard-v3"
      preemptible   = true
      nat           = true
    }
  ]
  description = "Database instances specifications for for_each loop"
}

### Storage VM and Disks variables (Task 3)
variable "storage_disk_count" {
  type        = number
  default     = 3
  description = "Number of secondary disks to create"
}

variable "storage_disk_size" {
  type        = number
  default     = 1
  description = "Size of each secondary disk in GB"
}

variable "storage_disk_name_prefix" {
  type        = string
  default     = "disk"
  description = "Prefix for storage secondary disk names"
}

variable "storage_vm_name" {
  type        = string
  default     = "storage"
  description = "Name for storage VM instance"
}

variable "storage_vm_resources" {
  type = object({
    platform_id   = string
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
    preemptible   = bool
    nat           = bool
  })
  default = {
    platform_id   = "standard-v3"
    cores         = 2
    memory        = 1
    core_fraction = 20
    disk_size     = 10
    preemptible   = true
    nat           = true
  }
  description = "Hardware specifications for storage instance"
}
