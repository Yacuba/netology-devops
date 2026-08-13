### vm_web variables

variable "vm_web_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Compute image family for web VM"
}

variable "vm_web_name" {
  type        = string
  default     = "netology-develop-platform-web"
  description = "Name for web VM"
}

variable "vm_web_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Platform ID for web VM"
}

# variable "vm_web_cores" {
#   type        = number
#   default     = 2
#   description = "Number of CPU cores for web VM"
# }

# variable "vm_web_memory" {
#   type        = number
#   default     = 1
#   description = "RAM size in GB for web VM"
# }

# variable "vm_web_core_fraction" {
#   type        = number
#   default     = 20
#   description = "Core fraction percentage for web VM"
# }

### vm_db variables

variable "vm_db_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Compute image family for db VM"
}

variable "vm_db_name" {
  type        = string
  default     = "netology-develop-platform-db"
  description = "Name for db VM"
}

variable "vm_db_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Platform ID for db VM"
}

# variable "vm_db_cores" {
#   type        = number
#   default     = 2
#   description = "Number of CPU cores for db VM"
# }

# variable "vm_db_memory" {
#   type        = number
#   default     = 2
#   description = "RAM size in GB for db VM"
# }

# variable "vm_db_core_fraction" {
#   type        = number
#   default     = 20
#   description = "Core fraction percentage for db VM"
# }

variable "vm_db_zone" {
  type        = string
  default     = "ru-central1-b"
  description = "Availability zone for db VM"
}

variable "vm_db_cidr" {
  type        = list(string)
  default     = ["10.0.2.0/24"]
  description = "Subnet CIDR block for db VM"
}

variable "vms_resources" {
  type = map(object({
    cores         = number
    memory        = number
    core_fraction = number
    hdd_size      = number
    hdd_type      = string
  }))
  description = "Resource specs for VMs"
}

variable "metadata" {
  type = object({
    serial-port-enable = number
    ssh-keys           = string
  })
  description = "Metadata map for VMs"
}