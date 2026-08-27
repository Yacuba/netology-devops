# Итоговый проект модуля «Облачная инфраструктура. Terraform»

---

## Подготовка окружения и Remote State

### 1. Структура проекта

Вся конфигурация инфраструктуры и исходный код приложения разделены по соответствующим директориям:

```text
ter-homeworks/final/
├── src/                      # HCL-код инфраструктуры Terraform
│   ├── .terraform.lock.hcl
│   ├── example.tfvars        # Пример файла переменных для воспроизведения стенда
│   ├── personal.auto.tfvars  # Персональные секретные переменные (исключен из git)
│   ├── providers.tf          # Конфигурация провайдеров и S3 Backend
│   └── variables.tf          # Объявление входных переменных
├── .gitignore                # Правила исключения временных и секретных файлов
└── README.md                 # Отчет о выполнении итогового проекта
```

---

### 2. Конфигурация Remote State со State Locking

Для обеспечения безопасной командной работы состояние инфраструктуры сохраняется в удаленном S3-бакете Object Storage `yacuba-tfstate-bucket-2026` с включенным нативным механизмом блокировок (`use_lockfile = true`).

Фрагмент `src/providers.tf`:

```hcl
terraform {

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.120.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
  required_version = "~>1.15.0"  

  backend "s3" {
    bucket  = "yacuba-tfstate-bucket-2026"
    key     = "terraform.tfstate"
    region  = "ru-central1"

    use_lockfile = true

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  service_account_key_file = file(var.service_account_key_file)
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
}
```

---

### 3. Инициализация проекта

Инициализация Terraform выполнена успешно: провайдеры загружены, подключение к удаленному S3 бэкенду установлено:  

![Инициализация Terraform с Remote S3 Backend](task_0_screenshot_1)

---

## Задание 1. Развертывание инфраструктуры в Yandex Cloud

Вся инфраструктура описана декларативно с использованием Terraform. Параметры вынесены в типизированные переменные `variables.tf`, а наименования ресурсов формируются централизованно в `locals.tf`.

### 1. Сетевая инфраструктура (VPC и подсеть)

Создана облачная сеть и подсеть в зоне доступности `ru-central1-a` с адресным пространством `10.10.1.0/24`.

Фрагмент `src/network.tf`:
```hcl
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
```

![Созданные VPC и подсеть в Yandex Cloud](task_1_screenshot_1)

---

### 2. Группы безопасности (Security Group)

Настроена группа безопасности с правилами входящего трафика для SSH (`22`), HTTP (`80`), HTTPS (`443`), порта веб-приложения (`8090`), а также полным внутренним доступом между ресурсами группы безопасности (для взаимодействия ВМ с MySQL по порту `3306`) и исходящим доступом в Интернет. Внешние правила сгенерированы динамическим блоком `dynamic "ingress"`.

Фрагмент `src/security_groups.tf`:
```hcl
# Security Group with dynamic ingress rules
resource "yandex_vpc_security_group" "sg" {
  name        = local.sg_name
  description = "Security group for ${local.name_prefix}"
  network_id  = yandex_vpc_network.vpc.id

  # Dynamic generation of external ingress rules
  dynamic "ingress" {
    for_each = var.security_group_ingress_rules
    content {
      protocol       = ingress.value.protocol
      description    = ingress.value.description
      port           = ingress.value.port
      v4_cidr_blocks = ingress.value.v4_cidr_blocks
    }
  }

  # Allow internal traffic within security group (App <-> DB)
  ingress {
    protocol          = "ANY"
    description       = "Allow internal traffic within security group"
    predefined_target = "self_security_group"
  }

  # Outbound Internet traffic
  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}
```

![Правила группы безопасности в Yandex Cloud](task_1_screenshot_2)

---

### 3. Реестр контейнеров (Yandex Container Registry)

Создан реестр контейнеров для хранения образов веб-приложения.

Фрагмент `src/registry.tf`:
```hcl
# Yandex Container Registry
resource "yandex_container_registry" "registry" {
  name      = local.registry_name
  folder_id = var.folder_id
}
```

![Созданный Yandex Container Registry](task_1_screenshot_3)

---

### 4. Кластер баз данных Managed Service for MySQL

Создан экономичный кластер MySQL 8.0 с одним хостом в созданной подсети, базой данных `virtd` и пользователем `app_user`. Кластер привязан к группе безопасности `final-prod-sg`.

Фрагмент `src/mysql.tf`:
```hcl
# Managed Service for MySQL Cluster
resource "yandex_mdb_mysql_cluster" "mysql" {
  name               = local.mysql_name
  environment        = var.mysql_cluster_config.environment
  network_id         = yandex_vpc_network.vpc.id
  version            = var.mysql_cluster_config.version
  security_group_ids = [yandex_vpc_security_group.sg.id]

  resources {
    resource_preset_id = var.mysql_cluster_config.resource_preset_id
    disk_type_id       = var.mysql_cluster_config.disk_type_id
    disk_size          = var.mysql_cluster_config.disk_size
  }

  host {
    zone             = var.default_zone
    subnet_id        = yandex_vpc_subnet.subnet.id
    assign_public_ip = var.mysql_cluster_config.assign_public_ip
  }

  # Ensure Lockbox secret version exists before creating cluster user
  depends_on = [yandex_lockbox_secret_version.mysql_password_version]
}

# MySQL Database
resource "yandex_mdb_mysql_database" "db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = var.mysql_db_config.db_name
}

# MySQL User reading password from Lockbox
resource "yandex_mdb_mysql_user" "user" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = var.mysql_db_config.username
  password   = [for entry in data.yandex_lockbox_secret_version.mysql_password_data.entries : entry.text_value if entry.key == var.lockbox_secret_key][0]

  permission {
    database_name = yandex_mdb_mysql_database.db.name
    roles         = var.mysql_db_config.roles
  }
}
```

![Работающий кластер Managed MySQL в Yandex Cloud](task_1_screenshot_5)

---

## Задание 2. Установка Docker и Docker Compose через cloud-init

Для автоматической инициализации виртуальной машины используется механизм `cloud-init` (`user-data`), который при первом запуске ВМ настраивает SSH-доступ, подключает официальный репозиторий Docker и устанавливает пакеты `docker-ce`, `docker-ce-cli`, `containerd.io` и плагин `docker-compose-plugin` (версия Compose v2), а также добавляет пользователя `ubuntu` в группу `docker`.

### 1. Манифест `cloud-init.yml`

Фрагмент `src/cloud-init.yml`:
```yaml
#cloud-config
users:
  - name: ${ssh_user}
    groups: sudo, docker
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_public_key}

package_update: true
package_upgrade: false

packages:
  - ca-certificates
  - curl
  - gnupg
  - git

runcmd:
  # Add official Docker GPG key
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  # Add official Docker APT repository
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  # Install Docker Engine, CLI, and Docker Compose plugin
  - apt-get update -y
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  # Enable and start Docker service
  - systemctl enable --now docker
  # Ensure user is in docker group
  - usermod -aG docker ${ssh_user}
```

---

### 2. Конфигурация виртуальной машины `vm.tf`

Фрагмент `src/vm.tf`:
```hcl
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
    })
  }

  depends_on = [
    yandex_vpc_subnet.subnet,
    yandex_vpc_security_group.sg
  ]
}
```

---

### 3. Результаты развертывания ВМ и проверки Docker

Виртуальная машина успешно создана в подсети `final-prod-subnet-ru-central1-a` и привязана к группе безопасности `final-prod-sg`:

![Созданная виртуальная машина с привязанной группой безопасности](task_2_screenshot_1)

После подключения к ВМ по SSH подтверждена корректная работа установленного через `cloud-init` Docker Engine и Docker Compose:

![Проверка установки Docker и Docker Compose на ВМ](task_2_screenshot_2)

---

## Задание 3. Сборка Docker-образа и сохранение в Yandex Container Registry

Исходный код веб-приложения на FastAPI расположен в публичном форк-репозитории:  
🔗 **[GitHub: Yacuba/shvirtd-example-python](https://github.com/Yacuba/shvirtd-example-python)**

### 1. Многоэтапный `Dockerfile.python` и `.dockerignore`

Для минимизации размера и изоляции сред сборки и выполнения реализована многоэтапная сборка (Multi-stage build) на базе легковесного базового образа `python:3.12-slim`:

Листинг `Dockerfile.python`:
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim

WORKDIR /app

COPY --from=0 /usr/local /usr/local

COPY . .

# Запускаем приложение с помощью uvicorn, делая его доступным по сети
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"] 
```

Листинг `.dockerignore`:
```text
.git
.gitignore
__pycache__
*.pyc
*.pyo
*.pyd
.venv
venv
ENV
.env
Dockerfile*
compose*.yaml
README.md
```

---

### 2. Сборка и отправка образа в Yandex Container Registry

Сборка образа выполнена с помощью `docker buildx` с отключением SLSA-аттестаций (`--provenance=false`) для полной совместимости со спецификацией манифестов YCR. Образ снабжен релизным тегом `v1.0.0` и плавающим тегом `latest`:

```bash
docker buildx build \
  --provenance=false \
  -t "cr.yandex/<REGISTRY_ID>/web-app:v1.0.0" \
  -t "cr.yandex/<REGISTRY_ID>/web-app:latest" \
  -f Dockerfile.python \
  --push .
```

![Сборка и push Docker-образа в Yandex Container Registry](task_3_screenshot_1)

Опубликованный Docker-образ в реестре Yandex Cloud:

![Docker-образ web-app с тегами v1.0.0 и latest в Yandex Container Registry](task_3_screenshot_2)

---

## Задание 4. Запуск приложения и интеграция с облачной базой данных MySQL

### 1. Манифест развертывания `compose.yaml`

Для развертывания веб-приложения на виртуальной машине подготовлен манифест `compose.yaml`, подключающий конфигурацию прокси-серверов `proxy.yaml` и использующий собранный Docker-образ из Yandex Container Registry. Переменные подключения к облачной БД MySQL передаются через `.env` файл:

```yaml
include:
  - proxy.yaml

services:
  web:
    image: cr.yandex/crpl14hckkr27ul3npcev/web-app:latest
    restart: always
    environment:
      DB_HOST: ${DB_HOST}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: ${DB_NAME}
      DB_PORT: ${DB_PORT:-3306}
    networks:
      backend:
        ipv4_address: 172.20.0.5

networks:
  backend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
```

---

### 2. Запуск контейнеров и проверка работоспособности

Стек сервисов запущен на виртуальной машине с помощью Docker Compose:

![Статус запущенных контейнеров и логи сервиса web](task_4_screenshot_1)

Веб-приложение успешно принимает клиентские запросы через цепочку `Пользователь → Nginx (8090) → HAProxy (8080) → FastAPI (5000)`:

![Ответ веб-приложения в браузере](task_4_screenshot_2)

---

### 3. Проверка сохранения данных в облачной БД MySQL

Проверка содержимого таблицы `requests` выполнена в веб-интерфейсе WebSQL консоли Yandex Cloud. В базе данных зафиксированы записи с временем запросов и внешними IP-адресами клиентов:

![Записи клиентских запросов в таблице requests кластера Managed MySQL](task_4_screenshot_3)

---

## Задание 5*. Безопасное хранение секретов в Yandex Lockbox

В соответствии с принципами безопасности пароль от базы данных не хранится в открытом виде в коде конфигурации. Пароль генерируется ресурсом `random_password`, сохраняется в хранилище секретов **Yandex Lockbox** и извлекается источником данных `data "yandex_lockbox_secret_version"` для передачи в пользователя MySQL.

Фрагмент `src/lockbox.tf`:
```hcl
# Generate secure random password for database
resource "random_password" "mysql_password" {
  length           = var.db_password_params.length
  special          = var.db_password_params.special
  override_special = var.db_password_params.override_special
}

# Yandex Lockbox Secret
resource "yandex_lockbox_secret" "mysql_secret" {
  name        = local.lockbox_name
  description = "MySQL database credentials for ${local.name_prefix}"
  folder_id   = var.folder_id
}

# Lockbox Secret Version storing the generated password
resource "yandex_lockbox_secret_version" "mysql_password_version" {
  secret_id = yandex_lockbox_secret.mysql_secret.id
  entries {
    key        = var.lockbox_secret_key
    text_value = random_password.mysql_password.result
  }
}

# Data source to read secret payload from Lockbox
data "yandex_lockbox_secret_version" "mysql_password_data" {
  secret_id  = yandex_lockbox_secret.mysql_secret.id
  version_id = yandex_lockbox_secret_version.mysql_password_version.id
}
```

![Секрет с паролем базы данных в Yandex Lockbox](task_1_screenshot_4)