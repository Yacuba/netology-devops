# Домашнее задание к занятию «Использование Terraform в команде»

## Задание 1

Для статического анализа кода были использованы утилиты `tflint` и `checkov` с запуском через Docker-контейнеры.

### 1. Результаты проверки директории `04/src`

Команды запуска:

```bash
docker run --rm -v "$(pwd):/data" -w /data ghcr.io/terraform-linters/tflint
docker run --rm --tty --volume "$(pwd):/tf" --workdir /tf bridgecrew/checkov --directory /tf --skip-download --framework terraform
```
  
![Chekov](task_1_screenshot_1)
  
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

![Успешная миграция состояния в S3 backend](task_2_screenshot_1)

---

### 2. Тестирование механизма блокировки State

> В ходе тестирования было замечено, что интерактивная сессия `terraform console` в современных версиях Terraform (v1.15.8) с S3 backend работает в режиме чтения и не накладывает эксклюзивную блокировку. 
> Для воспроизведения сценария конфликта блокировки в первом терминале была запущена команда `terraform apply`, которая удерживает лок на этапе ожидания пользовательского ввода (`Enter a value: `).

При попытке запустить параллельный `terraform apply` во втором окне терминала, Terraform вернул ошибку захвата блокировки (HTTP StatusCode: 412 PreconditionFailed от S3 API):

![Ошибка одновременного доступа к заблокированному state](task_2_screenshot_2)

---

### 3. Принудительное снятие блокировки (`force-unlock`)

Для снятия зависшей блокировки была выполнена команда:
```bash
terraform force-unlock 0ebd263f-4cf8-2acc-6633-b0fbf3fe6ae4
```

Результат выполнения команды:

![Успешная принудительная разблокировка состояния terraform force-unlock](task_2_screenshot_3)

