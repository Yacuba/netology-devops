# Fetch the latest Ubuntu 22.04 LTS image
data "yandex_compute_image" "ubuntu" {
  family = var.vm_web_config.image_family
}

# Compute Instance for Web Application
resource "yandex_compute_instance" "web" {
  name        = local.vm_name
  hostname    = local.vm_name
  platform_id = var.vm_web_config.platform_id
  zone        = var.default_zone

  resources {
    cores         = var.vm_web_config.cores
    memory        = var.vm_web_config.memory
    core_fraction = var.vm_web_config.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      type     = var.vm_web_config.disk_type
      size     = var.vm_web_config.disk_size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet.id
    nat                = var.vm_web_config.nat
    security_group_ids = [yandex_vpc_security_group.sg.id]
  }

  scheduling_policy {
    preemptible = var.vm_web_config.preemptible
  }

  metadata = {
    serial-port-enable = var.vm_web_config.serial_port_enable
    user-data = templatefile("${path.module}/cloud-init.yml", {
      ssh_user       = var.ssh_user
      ssh_public_key = file(pathexpand(var.ssh_public_key_path))
      db_host        = yandex_mdb_mysql_cluster.mysql.host[0].fqdn
      db_user        = var.mysql_db_config.username
      db_password    = [for entry in data.yandex_lockbox_secret_version.mysql_password_data.entries : entry.text_value if entry.key == var.lockbox_secret_key][0]
      db_name        = var.mysql_db_config.db_name
      registry_id    = yandex_container_registry.registry.id
    })
  }

  depends_on = [
    yandex_vpc_subnet.subnet,
    yandex_vpc_security_group.sg,
    yandex_mdb_mysql_cluster.mysql,
    yandex_lockbox_secret_version.mysql_password_version
  ]
}
