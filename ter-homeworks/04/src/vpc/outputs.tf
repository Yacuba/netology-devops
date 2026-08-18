output "network" {
  value       = yandex_vpc_network.network
  description = "Yandex VPC Network resource"
}

# output "subnet" {
#   value       = yandex_vpc_subnet.subnet
#   description = "Yandex VPC Subnet resource"
# }

output "network_id" {
  value       = yandex_vpc_network.network.id
  description = "VPC Network ID"
}

# output "subnet_id" {
#   value       = yandex_vpc_subnet.subnet.id
#   description = "VPC Subnet ID"
# }

output "subnet_ids" {
  value       = [for s in yandex_vpc_subnet.subnets : s.id]
  description = "List of subnet IDs"
}

output "subnets" {
  value       = yandex_vpc_subnet.subnets
  description = "Map of created Yandex VPC Subnet resources"
}
