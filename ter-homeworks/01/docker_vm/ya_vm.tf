terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  service_account_key_file = "/home/yachi/key.json"
  cloud_id                 = "b1g2glqlfp0vh6bf76s0"
  folder_id                = "b1gol0cjn3ithkecd3fb"
  zone                     = "ru-central1-a"
}


# сеть VPC
resource "yandex_vpc_network" "develop" {
  name = "develop"
}

# подсеть VPC
resource "yandex_vpc_subnet" "public-subnet" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["10.0.1.0/24"]
}

# данные об образе
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

# ВМ
resource "yandex_compute_instance" "docker_vm" {
  name        = "docker_vm"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20 # Экономия 
  }

  scheduling_policy {
    preemptible = true # Экономия
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public-subnet.id
    nat        = true
  }

    metadata = {
    ssh-keys  = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

# вывод публичного ip
output "vm_public_ip" {
  value = yandex_compute_instance.docker_vm.network_interface.0.nat_ip_address
}