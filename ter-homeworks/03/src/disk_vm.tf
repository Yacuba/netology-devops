# Create secondary disks via count loop
resource "yandex_compute_disk" "storage_disk" {
  count = var.storage_disk_count

  name = "${var.storage_disk_name_prefix}-${count.index + 1}"
  size = var.storage_disk_size
  zone = var.default_zone
}

# Create single storage instance with dynamic secondary_disk block
resource "yandex_compute_instance" "storage" {
  name        = var.storage_vm_name
  hostname    = var.storage_vm_name
  platform_id = var.storage_vm_resources.platform_id
  zone        = var.default_zone

  resources {
    cores         = var.storage_vm_resources.cores
    memory        = var.storage_vm_resources.memory
    core_fraction = var.storage_vm_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.storage_vm_resources.disk_size
    }
  }

  dynamic "secondary_disk" {
    for_each = yandex_compute_disk.storage_disk
    content {
      disk_id = secondary_disk.value.id
    }
  }

  scheduling_policy {
    preemptible = var.storage_vm_resources.preemptible
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop.id
    nat                = var.storage_vm_resources.nat
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = {
    serial-port-enable = local.vms_metadata.serial-port-enable
    ssh-keys           = local.vms_metadata.ssh-keys
  }
}