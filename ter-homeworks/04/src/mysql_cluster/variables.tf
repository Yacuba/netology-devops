variable "cluster_name" {
  type        = string
  description = "Name of the MySQL cluster"
}

variable "network_id" {
  type        = string
  description = "VPC Network ID"
}

variable "HA" {
  type        = bool
  default     = false
  description = "High Availability mode (false = 1 host, true = 2 hosts)"
}

variable "environment" {
  type        = string
  default     = "PRESTABLE"
  description = "Environment: PRESTABLE or PRODUCTION"
}

variable "version_mysql" {
  type        = string
  default     = "8.0"
  description = "MySQL version"
}

variable "resource_preset_id" {
  type        = string
  default     = "b1.medium"
  description = "Minimal burstable compute preset"
}

variable "disk_type_id" {
  type        = string
  default     = "network-ssd"
  description = "Disk type"
}

variable "disk_size" {
  type        = number
  default     = 10
  description = "Disk size in GB"
}

variable "host_count" {
    type        = number
    default = 2
    description = "Number of hosts in a cluster"
}

variable "hosts" {
  type = list(object({
    zone      = string
    subnet_id = string
  }))
  description = "List of hosts with zone and subnet_id"
}
