# Домашнее задание к занятию «Использование Terraform в команде»

## Задание 1

Для статического анализа кода были использованы утилиты `tflint` и `checkov` с запуском через Docker-контейнеры.

### 1. Результаты проверки директории `04/src`

Команды запуска:

```bash
docker run --rm -v "$(pwd):/data" -w /data ghcr.io/terraform-linters/tflint
docker run --rm --tty --volume "$(pwd):/tf" --workdir /tf bridgecrew/checkov --directory /tf --skip-download --framework terraform
```
  
<img width="308" height="156" alt="Снимок экрана 2026-08-20 162209" src="https://github.com/user-attachments/assets/5fc1d1a7-0f0e-4d63-8a4e-794f5e21ec2d" />
  
### 2. Перечень обнаруженных типов ошибок

1. **`terraform_required_providers` (tflint)**. Отсутствует ограничение версии для провайдера `yandex` в блоке `required_providers`.
2. **`terraform_unused_declarations` (tflint)**. Объявлены неиспользуемые переменные (`vms_ssh_root_key`, `vm_web_name`, `vm_db_name`).
3. **`CKV_TF_1` (checkov)**. Исходный код внешнего модуля не зафиксирован с помощью конкретного commit hash (`Ensure Terraform module sources use a commit hash`).
4. **`CKV_TF_2` (checkov)**. Исходный код внешнего модуля не зафиксирован с помощью тега с версией (`Ensure Terraform module sources use a tag with a version number`). Модуль ссылается на ветку `main` (`?ref=main`).

---

## Задание 2

### 1. Настройка remote state с встроенными блокировками

1. В Yandex Cloud был создан сервис-аккаунт `tf-state-sa` с ролью `storage.editor` и сгенерирован статический ключ доступа (Access Key / Secret Key).
2. S3-бакет `yacuba-tfstate-bucket-2026` для хранения состояния Terraform был создан в рамках предыдущего ДЗ.
3. В конфигурационном файле `providers.tf` настроен backend `s3` с параметром `use_lockfile = true` (нативная блокировка без DynamoDB):

```hcl
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    template = {
      source = "hashicorp/template"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }    
  }
  required_version = "~>1.15.0"

  backend "s3" {
    bucket  = "yacuba-tfstate-bucket-2026"
    key     = "terraform.tfstate"
    region  = "ru-central1"

    # Встроенный механизм блокировок (Terraform >= 1.6)
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
```

4. Выполнена инициализация и миграция состояния с помощью команды `terraform init -migrate-state`:  

<img width="571" height="283" alt="Снимок экрана 2026-08-20 173545" src="https://github.com/user-attachments/assets/5aceae01-7260-48b0-bdb6-4bf7d48dc919" />

### 2. Тестирование механизма блокировки State

> В ходе тестирования было замечено, что интерактивная сессия `terraform console` в современных версиях Terraform (v1.15.8) с S3 backend работает в режиме чтения и не накладывает эксклюзивную блокировку. 
> Для воспроизведения сценария конфликта блокировки в первом терминале была запущена команда `terraform apply`, которая удерживает лок на этапе ожидания пользовательского ввода (`Enter a value: `).

При попытке запустить параллельный `terraform apply` во втором окне терминала, Terraform вернул ошибку захвата блокировки (HTTP StatusCode: 412 PreconditionFailed от S3 API):  

<img width="750" height="303" alt="Снимок экрана 2026-08-20 175623" src="https://github.com/user-attachments/assets/92afc230-1916-4384-ab77-e454d45e4dff" />

### 3. Принудительное снятие блокировки (`force-unlock`)

Для снятия зависшей блокировки была выполнена команда:
```bash
terraform force-unlock 0ebd263f-4cf8-2acc-6633-b0fbf3fe6ae4
```

Результат выполнения команды:  

<img width="574" height="188" alt="Снимок экрана 2026-08-20 180007" src="https://github.com/user-attachments/assets/0006fbee-4cd4-4613-ba19-6f25b59d6026" />

---

## Задание 3

### 1. Устранение замечаний линтеров в ветке `terraform-hotfix`

1. Из ветки `terraform-05` создана ветка `terraform-hotfix`.
2. В коде проекта были устранены все предупреждения:
   * Источники внешних модулей в `main.tf` и `s3.tf` зафиксированы на конкретные commit SHA вместо плавающих веток (`main`/`master`).
   * В блоке `required_providers` файла `providers.tf` явно указаны версии провайдеров (`yandex` и `template`).
   * В `variables.tf` закомментированы неиспользуемые переменные (`default_cidr`, `vm_web_name`, `vm_db_name`).
   * Для ресурса MySQL кластера добавлен комментарий `#checkov:skip=CKV_YC_1` в связи с отсутствием требования отдельной Security Group для демонстрационного стенда.
3. Повторный запуск линтеров подтвердил устранение всех проблем:
   * **`tflint`**: 0 предупреждений.
   * **`checkov`**: `Passed checks: 12, Failed checks: 0, Skipped checks: 1`.

### 2. Pull Request

Создан Pull Request из ветки `terraform-hotfix` в `terraform-05`:
* **Ссылка на Pull Request:** [PR #1: Fix linting and security issues](https://github.com/Yacuba/netology-devops/pull/1)

---

## Задание 4

### 1. Объявление переменных с валидацией

В файле `variables_validation.tf` объявлены переменные с валидацией с использованием встроенных функций `cidrhost()`, `can()` и `alltrue()`:

```hcl
variable "ip_address" {
  type        = string
  description = "ip-address"
  default     = "192.168.0.1"

  validation {
    condition     = can(cidrhost("${var.ip_address}/32", 0))
    error_message = "Invalid IP address format. Must be a valid IPv4 address."
  }
}

variable "ip_list" {
  type        = list(string)
  description = "ip-address list"
  default     = ["192.168.0.1", "1.1.1.1", "127.0.0.1"]

  validation {
    condition     = alltrue([for ip in var.ip_list : can(cidrhost("${ip}/32", 0))])
    error_message = "One or more IP addresses in the list are invalid."
  }
}
```

---

### 2. Тестирование валидации в `terraform console`

#### Тест 1: Валидация строки IP (корректное значение `192.168.0.1`)  

<img width="135" height="59" alt="Снимок экрана 2026-08-20 202953" src="https://github.com/user-attachments/assets/def1d378-d7a6-442a-b821-d5d8325cc68c" />

#### Тест 2: Валидация строки IP (некорректное значение `192.1658.0.1`)  

<img width="553" height="197" alt="Снимок экрана 2026-08-20 203109" src="https://github.com/user-attachments/assets/a67e3ee8-7989-4665-93a2-8e6d99f1f9a1" />

#### Тест 3: Валидация списка IP (корректный список `["192.168.0.1", "1.1.1.1", "127.0.0.1"]`)  

<img width="121" height="106" alt="Снимок экрана 2026-08-20 203217" src="https://github.com/user-attachments/assets/95801cfd-283c-4e22-adc1-3412c8277eb4" />

#### Тест 4: Валидация списка IP (некорректный список с ошибочным адресом)  

<img width="571" height="200" alt="Снимок экрана 2026-08-20 203310" src="https://github.com/user-attachments/assets/d444b0e2-e9fb-4ade-af68-9dcb5f8f82bb" />

---

## Задание 5*

### 1. Объявление переменных с валидацией

В файле `variables_validation.tf` добавлены:
* Переменная `lowercase_string` с проверкой на отсутствие символов верхнего регистра с помощью функции `lower()`.
* Переменная `in_the_end_there_can_be_only_one` с логикой XOR (только один Маклауд может быть `true`):

```hcl
variable "lowercase_string" {
  type        = string
  description = "any string"
  default     = "lowercase_only_string"

  validation {
    condition     = var.lowercase_string == lower(var.lowercase_string)
    error_message = "The string must not contain uppercase characters."
  }
}

variable "in_the_end_there_can_be_only_one" {
  description = "Who is better Connor or Duncan?"
  type = object({
    Dunkan = optional(bool)
    Connor = optional(bool)
  })

  default = {
    Dunkan = true
    Connor = false
  }

  validation {
    error_message = "There can be only one MacLeod"
    condition     = (var.in_the_end_there_can_be_only_one.Dunkan != var.in_the_end_there_can_be_only_one.Connor)
  }
}
```

---

### 2. Тестирование в `terraform console`

#### Тест 1: Валидная строка только в нижнем регистре (`"lowercase_only_string"`)  

<img width="173" height="52" alt="Снимок экрана 2026-08-20 204235" src="https://github.com/user-attachments/assets/98c578fc-5811-46a5-9453-680361ff2fdb" />

#### Тест 2: Ошибка валидации строки с символами верхнего регистра (`"Not_Such_A_Lowercase_String"`)  

<img width="555" height="200" alt="Снимок экрана 2026-08-20 204532" src="https://github.com/user-attachments/assets/6ebaa116-f558-4fec-bb0c-2f427bae83c8" />

#### Тест 3: Валидный объект с одним истинным значением (`Dunkan = true, Connor = false`)  

<img width="288" height="118" alt="Снимок экрана 2026-08-20 204611" src="https://github.com/user-attachments/assets/462518fc-fbb4-45a7-936c-78e79be2b2d4" />

#### Тест 4: Ошибка валидации объекта, когда оба значения true (`Dunkan = true, Connor = true`)  

<img width="556" height="210" alt="Снимок экрана 2026-08-20 204642" src="https://github.com/user-attachments/assets/6cb348db-81cd-4996-95d7-6dabfb70192a" />

---

## Задание 6*

### 1. Настройка локального CI/CD на базе Jenkins

Для автоматизации развертывания и уничтожения инфраструктуры в изолированном защищенном контуре был настроен локальный Jenkins в Docker-контейнере с пробросом Docker-сокета и бинарного файла `terraform`.

В Jenkins была создана параметризованная задача `terraform-infrastructure` со строковым параметром выбора `Action` (`apply` / `destroy`).
Перед развертыванием (`apply`) выполняются статический анализ кода (`tflint`) и аудит безопасности (`checkov`).

### 2. Скрипт сборки (Execute Shell)

```bash
#!/bin/bash
set -e

# Clone or update the repository
if [ ! -d "netology-devops" ]; then
    git clone https://github.com/Yacuba/netology-devops.git
fi

cd netology-devops
git checkout terraform-05
git pull origin terraform-05

cd ter-homeworks/04/src

# Inject Service Account key for Yandex Cloud provider
cat << 'EOF' > authorized_key.json
{
  "id": "...",
  "service_account_id": "...",
  "created_at": "...",
  "key_algorithm": "RSA_2048",
  "public_key": "...",
  "private_key": "..."
}
EOF

# Inject personal variables (personal.auto.tfvars)
cat << 'EOF' > personal.auto.tfvars
service_account_key_file = "./authorized_key.json"
cloud_id                 = "cloud_id"
folder_id                = "folder_id"
vms_ssh_root_key         = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."
EOF

# Export credentials for S3 remote backend
export AWS_ACCESS_KEY_ID="access_key_id"
export AWS_SECRET_ACCESS_KEY="secret_access_key"

if [ "$Action" = "apply" ]; then
    echo "=========================================="
    echo " Static Analysis (TFLint)"
    echo "=========================================="
    docker run --rm -v "$(pwd):/data" -w /data ghcr.io/terraform-linters/tflint

    echo "=========================================="
    echo " Security Scan (Checkov)"
    echo "=========================================="
    docker run --rm -v "$(pwd):/tf" -w /tf bridgecrew/checkov --directory /tf --skip-download --framework terraform
fi

# Initialize Terraform
terraform init -reconfigure

# Execute requested action based on parameter
if [ "$Action" = "apply" ]; then
    terraform apply -auto-approve -target=module.marketing_vm
elif [ "$Action" = "destroy" ]; then
    terraform destroy -auto-approve
fi
```

### 3. Результаты выполнения пайплайна в Jenkins

#### Шаг 1: Развертывание инфраструктуры (`Action = apply`)  

Успешное прохождение проверок и развертывание ресурсов:

<img width="856" height="797" alt="Снимок экрана 2026-08-22 163524" src="https://github.com/user-attachments/assets/d3917aa8-c6be-4cde-8d79-bcb5f646db37" />

#### Шаг 2: Уничтожение инфраструктуры (`Action = destroy`)  

Полная очистка и удаление всех созданных ресурсов:

<img width="869" height="799" alt="Снимок экрана 2026-08-22 163630" src="https://github.com/user-attachments/assets/6ab5f4ec-8ef7-4bb0-ae29-58b0f295ac24" />

---

## Задание 7*

### 1. Отдельный Terraform Root-модуль для Remote State (`tfstate_backend`)

В директории `tfstate_backend` реализован изолированный модуль, декларативно подготавливающий инфраструктуру для хранения удаленного состояния Terraform.

**Ключевые инженерные решения в модуле:**
1. Все параметры (имена, роли, размер бакета, регион, endpoint) вынесены в `variables.tf`.
2. Генератор случайного суффикса `random_string` зафиксирован на каталог через `keepers`, исключая неконтролируемое пересоздание бакета при повторных запусках.
3. Использование `time_sleep` из провайдера `hashicorp/time` для гарантированного ожидания (15 с) распространения роли `storage.admin` и статического ключа перед созданием бакета и активацией версионирования.

Фрагмент `main.tf` (связка задержки распространения прав и включения версионирования):
```hcl
# Automatic delay for IAM propagation
resource "time_sleep" "wait_for_iam_propagation" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.storage_admin,
    yandex_iam_service_account_static_access_key.sa_static_key
  ]

  create_duration = "${var.iam_propagation_delay_seconds}s"
}

# S3 Bucket creation with versioning
resource "yandex_storage_bucket" "tfstate" {
  bucket                = "${var.bucket_prefix}-${random_string.bucket_suffix.result}"
  access_key            = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  max_size              = var.bucket_max_size
  default_storage_class = var.bucket_default_storage_class

  versioning {
    enabled = var.bucket_versioning_enabled
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.storage_admin
  ]
}
```

Фрагмент `outputs.tf` (динамическая генерация готовой конфигурации backend и защита секретов):
```hcl
output "bucket_name" {
  description = "The name of the created S3 bucket for tfstate"
  value       = yandex_storage_bucket.tfstate.bucket
}

output "access_key_id" {
  description = "Static Access Key ID for S3 backend"
  value       = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  sensitive   = true
}

output "secret_key" {
  description = "Secret Access Key for S3 backend"
  value       = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  sensitive   = true
}

output "backend_config_example" {
  description = "Dynamic backend configuration snippet for consumption in root modules"
  value       = <<-EOT
    terraform {
      required_version = "${var.terraform_required_version}"

      backend "s3" {
        bucket  = "${yandex_storage_bucket.tfstate.bucket}"
        key     = "${var.tfstate_key}"
        region  = "${var.s3_region}"

        # Native state locking mechanism
        use_lockfile = true

        endpoints = {
          s3 = "${var.s3_endpoint}"
        }

        skip_region_validation      = true
        skip_credentials_validation = true
        skip_requesting_account_id  = true
        skip_s3_checksum            = true
      }
    }
  EOT
}
```

### 2. Результаты применения

<img width="429" height="537" alt="Снимок экрана 2026-08-22 172848" src="https://github.com/user-attachments/assets/82c626b0-d692-41b7-80e7-0a117f576a3a" />
