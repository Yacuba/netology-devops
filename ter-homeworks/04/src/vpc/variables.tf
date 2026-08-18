variable "env_name" {
  type        = string
  description = "Environment or VPC network name"
}

# variable "zone" {
#   type        = string
#   description = "Availability zone for the subnet"
# }

# variable "cidr" {
#   type        = string
#   description = "CIDR IPv4 range for the subnet"
# }

variable "subnets" {
  type = list(object({
    zone = string
    cidr = string
  }))
  description = "List of subnets with zone and cidr"
}
