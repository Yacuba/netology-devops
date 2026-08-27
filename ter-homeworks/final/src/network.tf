# VPC Network
resource "yandex_vpc_network" "vpc" {
  name        = local.vpc_name
  description = "VPC network for ${local.name_prefix}"
}

# Subnet
resource "yandex_vpc_subnet" "subnet" {
  name           = local.subnet_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = [var.subnet_cidr]
}
