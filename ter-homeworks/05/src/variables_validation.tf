### Task 4: Single IP
variable "ip_address" {
  type        = string
  description = "ip-address"
  default     = "192.168.0.1"

  validation {
    condition     = can(cidrhost("${var.ip_address}/32", 0))
    error_message = "Invalid IP address format. Must be a valid IPv4 address."
  }
}

### Task 4: IP list
variable "ip_list" {
  type        = list(string)
  description = "ip-address list"
  default     = ["192.168.0.1", "1.1.1.1", "127.0.0.1"]

  validation {
    condition     = alltrue([for ip in var.ip_list : can(cidrhost("${ip}/32", 0))])
    error_message = "One or more IP addresses in the list are invalid."
  }
}

### Task 5*: Lowercase string
variable "lowercase_string" {
  type        = string
  description = "any string"
  default     = "lowercase_only_string"

  validation {
    condition     = var.lowercase_string == lower(var.lowercase_string)
    error_message = "The string must not contain uppercase characters."
  }
}

### Task 5*: There can be only one
variable "in_the_end_there_can_be_only_one" {
  description = "Who is better Connor or Duncan?"
  type = object({
    Dunkan = optional(bool)
    Connor = optional(bool)
  })

  default = {
    Dunkan = true
    Connor = false
  }

  validation {
    error_message = "There can be only one MacLeod"
    condition     = (var.in_the_end_there_can_be_only_one.Dunkan != var.in_the_end_there_can_be_only_one.Connor)
  }
}