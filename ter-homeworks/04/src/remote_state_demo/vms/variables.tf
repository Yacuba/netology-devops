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

variable "vms_ssh_root_key" {
  type        = string
  description = "SSH public key"
}

variable "serial_port_enable" {
  type        = number
  default     = 1
  description = "Enable serial console"
}

variable "vm_image_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "OS image family"
}

### Marketing VM vars
variable "vm_marketing" {
  type = object({
    env_name       = string
    instance_name  = string
    instance_count = number
    public_ip      = bool
    owner          = string
    project        = string
  })
  default = {
    env_name       = "marketing"
    instance_name  = "marketing-vm"
    instance_count = 1
    public_ip      = true
    owner          = "i.ivanov"
    project        = "marketing"
  }
  description = "Marketing VM configuration"
}

### Analytics VM vars
variable "vm_analytics" {
  type = object({
    env_name       = string
    instance_name  = string
    instance_count = number
    public_ip      = bool
    owner          = string
    project        = string
  })
  default = {
    env_name       = "analytics"
    instance_name  = "analytics-vm"
    instance_count = 1
    public_ip      = true
    owner          = "i.ivanov"
    project        = "analytics"
  }
  description = "Analytics VM configuration"
}
