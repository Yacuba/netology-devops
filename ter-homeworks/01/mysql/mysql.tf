terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

# подключение к Docker на удаленной ВМ по SSH
provider "docker" {
  host = "ssh://ubuntu@51.250.90.250:22"
  ssh_opts = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null"
  ]
}

# генерация root-пароля для MySQL
resource "random_password" "mysql_root_password" {
  length      = 16
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

# генерация пользовательского пароля для MySQL
resource "random_password" "mysql_user_password" {
  length      = 16
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

# загрузка образа MySQL 8
resource "docker_image" "mysql" {
  name         = "mysql:8"
  keep_locally = true
}

# запуск контейнера MySQL на ВМ
resource "docker_container" "mysql" {
  image = docker_image.mysql.image_id
  name  = "mysql_server"

  ports {
    ip       = "127.0.0.1"
    internal = 3306
    external = 3306
  }

  env = [
    "MYSQL_ROOT_PASSWORD=${random_password.mysql_root_password.result}",
    "MYSQL_DATABASE=wordpress",
    "MYSQL_USER=wordpress",
    "MYSQL_PASSWORD=${random_password.mysql_user_password.result}",
    "MYSQL_ROOT_HOST=%"
  ]
}