resource "yandex_compute_instance" "web" {
  count = var.web_vm_count

  name        = "${var.web_vm_name_prefix}-${count.index + 1}"
  hostname    = "${var.web_vm_name_prefix}-${count.index + 1}"
  platform_id = var.web_vm_resources.platform_id
  zone        = var.default_zone

  resources {
    cores         = var.web_vm_resources.cores
    memory        = var.web_vm_resources.memory
    core_fraction = var.web_vm_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = var.web_vm_resources.disk_size
    }
  }

  scheduling_policy {
    preemptible = var.web_vm_resources.preemptible
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop.id
    nat                = var.web_vm_resources.nat
    security_group_ids = [yandex_vpc_security_group.example.id]
  }

  metadata = {
    serial-port-enable = local.vms_metadata.serial-port-enable
    ssh-keys           = local.vms_metadata.ssh-keys
  }

  depends_on = [yandex_compute_instance.db]
}
