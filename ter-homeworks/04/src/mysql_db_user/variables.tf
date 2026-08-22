variable "cluster_id" {
  type        = string
  description = "MySQL Cluster ID"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "user_name" {
  type        = string
  description = "Database user name"
}

variable "user_password" {
  type        = string
  default     = "StrongPassword123!"
  sensitive   = true
  description = "Database user password"
}
