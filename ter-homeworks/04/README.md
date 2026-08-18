# Домашнее задание к занятию «Продвинутые методы работы с Terraform»

## Задание 1

1. С помощью готового remote-модуля `udjin10/yandex_compute_instance` созданы две виртуальные машины для разных проектов (`marketing` и `analytics`).
2. В файле `cloud-init.yml` настроена динамическая подстановка SSH-ключа через переменную и добавлена установка пакета `nginx`.

### Файл `cloud-init.yml`
```yaml
#cloud-config
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_public_key}
package_update: true
package_upgrade: false
packages:
  - vim
  - nginx
```

### Фрагмент `main.tf`
```terraform
data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    ssh_public_key = var.vms_ssh_root_key
  }
}

module "marketing_vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name       = var.vm_marketing.env_name
  network_id     = yandex_vpc_network.develop.id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [yandex_vpc_subnet.develop.id]
  instance_name  = var.vm_marketing.instance_name
  instance_count = var.vm_marketing.instance_count
  image_family   = var.vm_image_family
  public_ip      = var.vm_marketing.public_ip

  labels = { 
    owner   = var.vm_marketing.owner,
    project = var.vm_marketing.project
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = var.serial_port_enable
  }
}

module "analytics_vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name       = var.vm_analytics.env_name
  network_id     = yandex_vpc_network.develop.id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [yandex_vpc_subnet.develop.id]
  instance_name  = var.vm_analytics.instance_name
  instance_count = var.vm_analytics.instance_count
  image_family   = var.vm_image_family
  public_ip      = var.vm_analytics.public_ip

  labels = { 
    owner   = var.vm_analytics.owner,
    project = var.vm_analytics.project
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = var.serial_port_enable
  }
}
```

### Результаты выполнения

1. Подключение к виртуальной машине по SSH и проверка статуса и конфигурации Nginx (`sudo nginx -t`):  
<img width="471" height="55" alt="Снимок экрана 2026-08-16 214012" src="https://github.com/user-attachments/assets/ff2e2002-0e8f-4769-8686-92ab2e1163c1" /><br>

2. Метки (labels) виртуальных машин в консоли Yandex Cloud:  
<img width="601" height="327" alt="Снимок экрана 2026-08-16 214854" src="https://github.com/user-attachments/assets/501a55eb-3150-4114-b0bc-884c2f3abae0" /><br>
<img width="588" height="323" alt="Снимок экрана 2026-08-16 214918" src="https://github.com/user-attachments/assets/6766479c-0d69-47b2-bdf5-fcae729faa4c" /><br>

3. Вывод состояния модуля `module.marketing_vm` в `terraform console`:  
<img width="507" height="534" alt="Снимок экрана 2026-08-16 215158" src="https://github.com/user-attachments/assets/898c27f7-7a21-47b4-bf8c-c15606a0d353" /><br>

---

## Задание 2

1. Разработан локальный модуль `vpc` в директории `./vpc`, создающий облачную сеть `yandex_vpc_network` и подсеть `yandex_vpc_subnet` в заданной зоне доступности.
2. В модуль передаются входные переменные `env_name`, `zone` и `cidr`.
3. Модуль возвращает созданные ресурсы сети и подсети через блок `output`.
4. В корневом модуле прямые ресурсы сети и подсети заменены вызовом модуля `module.vpc_dev`, а его outputs переданы в модули виртуальных машин.
5. С помощью утилиты `terraform-docs` автоматически сгенерирована документация модуля в файле `./vpc/README.md`.

### Исходный код модуля `vpc`

#### `vpc/variables.tf`
```terraform
variable "env_name" {
  type        = string
  description = "Environment or VPC network name"
}

variable "zone" {
  type        = string
  description = "Availability zone for the subnet"
}

variable "cidr" {
  type        = string
  description = "CIDR IPv4 range for the subnet"
}
```

#### `vpc/main.tf`
```terraform
resource "yandex_vpc_network" "network" {
  name = var.env_name
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "${var.env_name}-${var.zone}"
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [var.cidr]
}
```

#### `vpc/outputs.tf`
```terraform
output "network" {
  value       = yandex_vpc_network.network
  description = "Yandex VPC Network resource"
}

output "subnet" {
  value       = yandex_vpc_subnet.subnet
  description = "Yandex VPC Subnet resource"
}

output "network_id" {
  value       = yandex_vpc_network.network.id
  description = "VPC Network ID"
}

output "subnet_id" {
  value       = yandex_vpc_subnet.subnet.id
  description = "VPC Subnet ID"
}
```

### Вызов модуля в корневом `main.tf`
```terraform
module "vpc_dev" {
  source   = "./vpc"
  env_name = var.vpc_name
  zone     = var.default_zone
  cidr     = var.default_cidr[0]
}
```

### Результаты выполнения

1. Вывод информации о созданном модуле `module.vpc_dev` в `terraform console`:  
<img width="412" height="564" alt="Снимок экрана 2026-08-18 164359" src="https://github.com/user-attachments/assets/76c8e467-1740-4143-ac6e-d0bfe4a5b0e9" /><br>

2. Автоматически сгенерированная документация модуля (`./vpc/README.md`):
Документация сгенерирована командой:
```bash
terraform-docs markdown table --output-file README.md ./vpc
```

---

## Задание 3

1. Просмотрен текущий список ресурсов в стейте.  
<img width="541" height="139" alt="Снимок экрана 2026-08-18 172001" src="https://github.com/user-attachments/assets/faf57d0c-69bc-4855-acb0-8fe91593451b" /><br>
2. Модули `module.vpc_dev`, `module.marketing_vm` и `module.analytics_vm` полностью удалены из стейта.  
<img width="673" height="241" alt="Снимок экрана 2026-08-18 172654" src="https://github.com/user-attachments/assets/d7510e75-4a74-4227-b539-e7975c340de8" /><br>
3. Все ресурсы импортированы обратно по их ID в Yandex Cloud.  
<img width="554" height="93" alt="Снимок экрана 2026-08-18 173626" src="https://github.com/user-attachments/assets/7604e4b5-f757-4573-8710-0b395e5ce3fb" /><br>
4. Выполнена проверка через `terraform plan`. Значимых изменений и пересоздания инфраструктуры нет (`0 to add, 2 to change, 0 to destroy`).  
<img width="584" height="408" alt="Снимок экрана 2026-08-18 173724" src="https://github.com/user-attachments/assets/ee3120de-7359-4d55-8e8c-0cae39151a0b" /><br>

### Выполненные команды

```bash
# просмотр списка ресурсов в стейте
terraform state list

# удаление модулей из стейта
terraform state rm module.vpc_dev
terraform state rm module.marketing_vm
terraform state rm module.analytics_vm

# проверка очистки стейта
terraform state list

# импорт ресурсов обратно в стейт
terraform import module.vpc_dev.yandex_vpc_network.network enpfql7c6jla83rfbss7
terraform import module.vpc_dev.yandex_vpc_subnet.subnet e9bg0rk2en3fc4na5qjd
terraform import 'module.marketing_vm.yandex_compute_instance.vm[0]' fhmtjvpiamu1g8uggbko
terraform import 'module.analytics_vm.yandex_compute_instance.vm[0]' fhmdq7m05e4cji39ma2k

# проверка состояния инфраструктуры
terraform plan
```

---

## Задание 4*

1. Модуль `vpc` модифицирован для динамического создания произвольного количества подсетей в различных зонах доступности через переменную типа `list(object)` с использованием цикла `for_each`.
2. Входные параметры и код корневого модуля обновлены для передачи списка подсетей (`ru-central1-a`, `ru-central1-b`, `ru-central1-d`).
3. При первой попытке выполнения `terraform apply` были успешно созданы новые подсети (`ru-central1-b`, `ru-central1-d`), однако возникла ошибка при попытке удаления и повторного создания подсети `ru-central1-a`, так как к ней были привязаны работающие ВМ, а адресное пространство `10.0.1.0/24` конфликтовало).  
<img width="998" height="336" alt="Снимок экрана 2026-08-18 181717" src="https://github.com/user-attachments/assets/80e96021-2b81-4669-af58-25f4314668b9" /><br>
4. Проблема была решена без разрушения инфраструктуры путем миграции ресурса в стейте (`terraform state mv`), после чего повторный запуск `terraform apply` завершился успешно.
```bash
terraform state mv 'module.vpc_dev.yandex_vpc_subnet.subnet' 'module.vpc_dev.yandex_vpc_subnet.subnets["ru-central1-a"]'
```
<img width="775" height="562" alt="Снимок экрана 2026-08-18 182220" src="https://github.com/user-attachments/assets/38302cec-cb0a-488d-9b61-b550d8f1cf93" /><br>

### Исходный код обновленного модуля `vpc`

#### `vpc/variables.tf`
```terraform
variable "env_name" {
  type        = string
  description = "Environment or VPC network name"
}

variable "subnets" {
  type = list(object({
    zone = string
    cidr = string
  }))
  description = "List of subnets with zone and cidr"
}
```

#### `vpc/main.tf`
```terraform
resource "yandex_vpc_network" "network" {
  name = var.env_name
}

resource "yandex_vpc_subnet" "subnets" {
  for_each       = { for s in var.subnets : s.zone => s }
  name           = "${var.env_name}-${each.value.zone}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = [each.value.cidr]
}
```

#### `vpc/outputs.tf`
```terraform
output "network" {
  value       = yandex_vpc_network.network
  description = "Yandex VPC Network resource"
}

output "network_id" {
  value       = yandex_vpc_network.network.id
  description = "VPC Network ID"
}

output "subnet_ids" {
  value       = [for s in yandex_vpc_subnet.subnets : s.id]
  description = "List of subnet IDs"
}

output "subnets" {
  value       = yandex_vpc_subnet.subnets
  description = "Map of created Yandex VPC Subnet resources"
}
```

### Вызов модуля в корневом `main.tf`
```terraform
module "vpc_dev" {
  source   = "./vpc"
  env_name = var.vpc_name
  subnets  = var.subnets_dev
}
```

### Итоговый список созданных подсетей во всех зонах доступности в консоли Yandex Cloud:  
<img width="1142" height="131" alt="Снимок экрана 2026-08-18 182459" src="https://github.com/user-attachments/assets/9dfd8e1e-3b3d-4973-904a-ea4a1ae1c2ce" /><br>

---

## Задание 5*

1. Разработан модуль `mysql_cluster` для создания управляемого кластера MySQL в Yandex Cloud с поддержкой переключения высокой доступности (`HA = true/false`) и возможностью регулировки количества хостов через `host_count`.
2. Разработан модуль `mysql_db_user` для создания базы данных и пользователя с полными правами в существующем кластере.
3. В корневом модуле параметры передаются через `variables.tf`, а подсети формируются динамически через выражение `for` из вывода модуля `module.vpc_dev.subnets`.
4. Протестировано создание кластера с 1 хостом (Master), БД `test` и пользователем `app`. Затем переключен флаг `HA = true` и успешно добавлен 2-й хост (Replica).

### Исходный код модулей

#### `mysql_cluster/main.tf`
```terraform
resource "yandex_mdb_mysql_cluster" "cluster" {
  name        = var.cluster_name
  environment = var.environment
  network_id  = var.network_id
  version     = var.version_mysql

  resources {
    resource_preset_id = var.resource_preset_id
    disk_type_id       = var.disk_type_id
    disk_size          = var.disk_size
  }

  dynamic "host" {
    for_each = var.HA ? slice(var.hosts, 0, var.host_count) : slice(var.hosts, 0, 1)
    content {
      zone      = host.value.zone
      subnet_id = host.value.subnet_id
    }
  }
}
```

#### `mysql_db_user/main.tf`
```terraform
resource "yandex_mdb_mysql_database" "db" {
  cluster_id = var.cluster_id
  name       = var.db_name
}

resource "yandex_mdb_mysql_user" "user" {
  cluster_id = var.cluster_id
  name       = var.user_name
  password   = var.user_password

  permission {
    database_name = yandex_mdb_mysql_database.db.name
    roles         = ["ALL"]
  }
}
```

### Вызов модулей в корневом `main.tf`
```terraform
# MySQL cluster
module "mysql_cluster" {
  source       = "./mysql_cluster"
  cluster_name = var.mysql_cluster_config.cluster_name
  network_id   = module.vpc_dev.network_id
  HA           = var.mysql_cluster_config.HA
  hosts = [
    for zone, subnet in module.vpc_dev.subnets : {
      zone      = zone
      subnet_id = subnet.id
    }
  ]
}

# DB and its user
module "mysql_db_user" {
  source     = "./mysql_db_user"
  cluster_id = module.mysql_cluster.cluster_id
  db_name    = var.mysql_db_config.db_name
  user_name  = var.mysql_db_config.user_name
}
```

### Результаты выполнения

1. Создание кластера `example` из одного хоста (`HA = false`), базы `test` и пользователя `app`:  
<img width="570" height="639" alt="Снимок экрана 2026-08-18 201041" src="https://github.com/user-attachments/assets/41ea8c34-03c9-4ff7-a330-52cca7502408" /><br>
<img width="176" height="134" alt="Снимок экрана 2026-08-18 201205" src="https://github.com/user-attachments/assets/5b63f64c-2bcf-4e3e-a0ec-dda2f1579938" /><br>

2. Масштабирование кластера до 2 хостов (`HA = true`):
<img width="807" height="143" alt="Снимок экрана 2026-08-18 202457" src="https://github.com/user-attachments/assets/32eb58ba-6f2a-4c8a-84c9-6f1294cc8931" /><br>

---

## Задание 6*

1. С использованием готового remote-модуля `terraform-yc-modules/terraform-yc-s3` создан S3-бакет в Yandex Object Storage с лимитом размера 1 ГБ (1073741824 байт).
2. Для совместимости с модулем в `providers.tf` настроена заглушка для провайдера AWS.

### Исходный код конфигурации

#### Фрагмент `providers.tf`
```terraform
provider "aws" {
  region                      = "ru-central1"
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  access_key                  = "mock_key"
  secret_key                  = "mock_key"
}
```

#### `s3.tf`
```terraform
module "s3_bucket" {
  source      = "git::https://github.com/terraform-yc-modules/terraform-yc-s3.git?ref=master"
  bucket_name = var.bucket_name
  max_size    = 1073741824 # 1 ГБ
}
```

### Результаты выполнения

1. Создание S3-бакета через точечное применение `terraform apply -target=module.s3_bucket`:  
<img width="738" height="78" alt="Снимок экрана 2026-08-18 205739" src="https://github.com/user-attachments/assets/74f8d056-2a4e-4396-a22c-88df7e88e261" /><br>

2. Созданный бакет в консоли Yandex Object Storage:  
<img width="1010" height="209" alt="Снимок экрана 2026-08-18 205909" src="https://github.com/user-attachments/assets/8b1f4d5c-dd8a-42ac-a6a1-d9968564cdb5" /><br>

---

## Задание 7*

1. Локально развернут контейнер HashiCorp Vault с использованием `docker-compose.yml`.
2. В веб-интерфейсе Vault создан секрет по пути `secret/example` (`test: congrats!`).  
<img width="1049" height="589" alt="Снимок экрана 2026-08-18 210815" src="https://github.com/user-attachments/assets/88c951a6-bfe0-4b14-8120-36d1412f8da0" /><br>
3. С помощью источника данных `data "vault_generic_secret"` секрет прочитан в Terraform и выведен в output через функцию `nonsensitive()`.  
<img width="703" height="199" alt="Снимок экрана 2026-08-18 212430" src="https://github.com/user-attachments/assets/b3eadf07-558e-4fcc-afa2-df47fb3bf4ff" /><br>
4. С помощью ресурса `vault_kv_secret_v2` средствами Terraform создан новый секрет `secret/terraform_secret`.  
<img width="1076" height="592" alt="Снимок экрана 2026-08-18 212828" src="https://github.com/user-attachments/assets/353eb08a-2675-4ee5-a10e-0bf189a00df0" /><br>

### Исходный код конфигурации

#### `vault/docker-compose.yml`
```yaml
services:
  vault:
    image: hashicorp/vault:latest
    container_name: vault
    ports:
      - "8200:8200"
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: "education"
      VAULT_DEV_LISTEN_ADDRESS: "0.0.0.0:8200"
    cap_add:
      - IPC_LOCK
```

#### `vault/providers.tf`
```terraform
terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">= 5.0.0"
    }
  }
}

# Configure the HashiCorp Vault Provider
provider "vault" {
  address         = "http://127.0.0.1:8200"
  skip_tls_verify = true
  token           = "education"
}
```

#### `vault/main.tf`
```terraform
# Read existing secret from Vault
data "vault_generic_secret" "vault_example" {
  path = "secret/example"
}

# Write a new secret into Vault
resource "vault_kv_secret_v2" "terraform_secret" {
  mount               = "secret"
  name                = "terraform_secret"
  delete_all_versions = true
  data_json = jsonencode({
    db_password = "SuperSecretPassword2026!"
    api_token   = "netology-token-xyz"
  })
}
```

#### `vault/outputs.tf`
```terraform
# Output data retrieved from the existing secret
output "vault_example" {
  value       = nonsensitive(data.vault_generic_secret.vault_example.data)
  description = "Data retrieved from secret/example"
}

# Output the name of the secret created by Terraform
output "created_terraform_secret_name" {
  value       = vault_kv_secret_v2.terraform_secret.name
  description = "Name of the newly created KV v2 secret"
}
```

---

## Задание 8*

1. Корневой модуль разделен на два независимых root-модуля с изолированными стейтами:
   * **`remote_state_demo/vpc`** — создание базовой сетевой инфраструктуры (VPC и подсети);
   * **`remote_state_demo/vms`** — развертывание виртуальных машин (`marketing` и `analytics`).
2. В модуле виртуальных машин настроено считывание состояния сетевого модуля через источник данных `data "terraform_remote_state"`.
3. Параметры сети (`network_id`, `subnet_ids`) переданы в модули ВМ напрямую из выгруженного стейта модуля VPC.

### Ключевые фрагменты конфигурации

#### 1. Экспорт параметров сети в `remote_state_demo/vpc/outputs.tf`
```terraform
output "network_id" {
  value       = module.vpc.network_id
  description = "Created VPC Network ID"
}

output "subnets" {
  value       = module.vpc.subnets
  description = "Map of created Subnet objects"
}

output "subnet_ids" {
  value       = module.vpc.subnet_ids
  description = "List of created Subnet IDs"
}
```

#### 2. Считывание стейта и использование в `remote_state_demo/vms/main.tf`
```terraform
data "terraform_remote_state" "vpc" {
  backend = "local"

  config = {
    path = "../vpc/terraform.tfstate"
  }
}

# Deploy VM using outputs from remote state
module "marketing_vm" {
  source         = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name       = var.vm_marketing.env_name
  network_id     = data.terraform_remote_state.vpc.outputs.network_id
  subnet_zones   = [var.default_zone]
  subnet_ids     = [data.terraform_remote_state.vpc.outputs.subnets[var.default_zone].id]
  instance_name  = var.vm_marketing.instance_name
  instance_count = var.vm_marketing.instance_count
  image_family   = var.vm_image_family
  public_ip      = var.vm_marketing.public_ip

  labels = { 
    owner   = var.vm_marketing.owner,
    project = var.vm_marketing.project
  }

  metadata = {
    user-data          = data.template_file.cloudinit.rendered
    serial-port-enable = var.serial_port_enable
  }
}
```

### Результаты выполнения

Успешное создание виртуальных машин во 2-м модуле на базе параметров сети, полученных из Remote State:
<img width="433" height="180" alt="Снимок экрана 2026-08-18 223345" src="https://github.com/user-attachments/assets/247f8578-0f0d-4765-bb8e-53695d583e0f" />
