### General & Authentication Variables
variable "service_account_key_file" {
  type        = string
  description = "Path to authorized key JSON for Yandex Cloud SA"
}

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
  description = "Default availability zone"
}

variable "project_name" {
  type        = string
  default     = "final"
  description = "Project name prefix"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Deployment environment (prod, stage, dev)"
}

### Network Variables
variable "subnet_cidr" {
  type        = string
  default     = "10.10.1.0/24"
  description = "CIDR block for public/app subnet"
}

### Security Group Variables
variable "security_group_ingress_rules" {
  type = list(object({
    protocol       = string
    description    = string
    port           = number
    v4_cidr_blocks = list(string)
  }))
  default = [
    {
      protocol       = "TCP"
      description    = "SSH access"
      port           = 22
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
    {
      protocol       = "TCP"
      description    = "HTTP access"
      port           = 80
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
    {
      protocol       = "TCP"
      description    = "HTTPS access"
      port           = 443
      v4_cidr_blocks = ["0.0.0.0/0"]
    },
    {
      protocol       = "TCP"
      description    = "Application ingress-proxy port"
      port           = 8090
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  description = "List of public ingress rules for security group"
}

### Lockbox & Password Variables
variable "db_password_params" {
  type = object({
    length           = number
    special          = bool
    override_special = string
  })
  default = {
    length           = 16
    special          = true
    override_special = "!#$%&*()-_=+[]{}<>:?"
  }
  description = "Password generator settings"
}

variable "lockbox_secret_key" {
  type        = string
  default     = "db_password"
  description = "Key name inside Lockbox secret payload"
}

### MySQL Cluster Variables
variable "mysql_cluster_config" {
  type = object({
    environment         = string
    version             = string
    resource_preset_id  = string
    disk_type_id        = string
    disk_size           = number
    assign_public_ip    = bool
  })
  default = {
    environment         = "PRESTABLE"
    version             = "8.0"
    resource_preset_id = "b1.medium"
    disk_type_id        = "network-hdd"
    disk_size           = 10
    assign_public_ip    = false
  }
  description = "Hardware and deployment configuration for MySQL cluster"
}

variable "mysql_db_config" {
  type = object({
    db_name  = string
    username = string
    roles    = list(string)
  })
  default = {
    db_name  = "virtd"
    username = "app_user"
    roles    = ["ALL"]
  }
  description = "Database and application user settings"
}

### VM & SSH Variables
variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to public SSH key"
}

variable "ssh_user" {
  type        = string
  default     = "ubuntu"
  description = "Default SSH user for VM"
}

### Web Virtual Machine Configuration
variable "vm_web_config" {
  type = object({
    platform_id        = string
    cores              = number
    memory             = number
    core_fraction      = number
    disk_type          = string
    disk_size          = number
    image_family       = string
    nat                = bool
    preemptible        = bool
    serial_port_enable = number
  })
  default = {
    platform_id        = "standard-v3"
    cores              = 2
    memory             = 2
    core_fraction      = 20
    disk_type          = "network-hdd"
    disk_size          = 15
    image_family       = "ubuntu-2204-lts"
    nat                = true
    preemptible        = true
    serial_port_enable = 1
  }
  description = "Hardware specifications and boot settings for web VM"
}
