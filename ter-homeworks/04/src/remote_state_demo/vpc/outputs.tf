output "network_id" {
  value       = module.vpc.network_id
  description = "Created VPC Network ID"
}

output "subnets" {
  value       = module.vpc.subnets
  description = "Map of created Subnet objects"
}

output "subnet_ids" {
  value       = module.vpc.subnet_ids
  description = "List of created Subnet IDs"
}
