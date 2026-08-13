resource "yandex_vpc_network" "develop" {
  name = var.vpc_name
}
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "egress-nat-gateway"
  shared_egress_gateway {}
}
resource "yandex_vpc_route_table" "rt" {
  name       = "nat-route-table"
  network_id = yandex_vpc_network.develop.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
resource "yandex_vpc_subnet" "develop" {
  name           = var.vpc_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = var.default_cidr
  route_table_id = yandex_vpc_route_table.rt.id
}
resource "yandex_vpc_subnet" "develop_b" {
  name           = "${var.vpc_name}-b"
  zone           = var.vm_db_zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = var.vm_db_cidr
  route_table_id = yandex_vpc_route_table.rt.id
}

data "yandex_compute_image" "ubuntu" {
  family = var.vm_web_image_family
}
resource "yandex_compute_instance" "platform" {
  name        = local.vm_web_name
  hostname    = local.vm_web_name
  platform_id = var.vm_web_platform_id
  resources {
    cores         = var.vms_resources.web.cores
    memory        = var.vms_resources.web.memory
    core_fraction = var.vms_resources.web.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size = var.vms_resources.web.hdd_size
      type = var.vms_resources.web.hdd_type
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = false
  }

  metadata = {
    serial-port-enable = var.metadata.serial-port-enable
    ssh-keys           = var.metadata.ssh-keys
  }

}

resource "yandex_compute_instance" "platform_db" {
  name        = local.vm_db_name
  hostname    = local.vm_db_name
  platform_id = var.vm_db_platform_id
  zone        = var.vm_db_zone

  resources {
    cores         = var.vms_resources.db.cores
    memory        = var.vms_resources.db.memory
    core_fraction = var.vms_resources.db.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size = var.vms_resources.web.hdd_size
      type = var.vms_resources.web.hdd_type
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop_b.id
    nat       = false
  }

  metadata = {
    serial-port-enable = var.metadata.serial-port-enable
    ssh-keys           = var.metadata.ssh-keys
  }
  
}
