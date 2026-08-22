resource "yandex_vpc_network" "network" {
  name = var.env_name
}

# resource "yandex_vpc_subnet" "subnet" {
#   name           = "${var.env_name}-${var.zone}"
#   zone           = var.zone
#   network_id     = yandex_vpc_network.network.id
#   v4_cidr_blocks = [var.cidr]
# }

resource "yandex_vpc_subnet" "subnets" {
  for_each       = { for s in var.subnets : s.zone => s }
  name           = "${var.env_name}-${each.value.zone}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [each.value.cidr]
}
