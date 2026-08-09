# Домашнее задание к занятию «Введение в Terraform»

## Чек-лист готовности

1. Установлен Terraform (версия `v1.15.8`).
2. Скачан исходный код из git-репозитория в директорию `01/src`.
3. Установлен и запущен **Docker Engine**.

<img width="617" height="103" alt="Снимок экрана 2026-08-09 212022" src="https://github.com/user-attachments/assets/0a89ee83-6757-4402-82c7-c9d576edad62" />

---

## Задание 1

1. Инициализация проекта  
В файле `main.tf` скорректировано ограничение версии `required_version = ">= 1.12.0"`. Выполнена команда `terraform init`, скачавшая необходимые провайдеры (`kreuzwerker/docker` и `hashicorp/random`).

<img width="566" height="157" alt="Снимок экрана 2026-08-09 212042" src="https://github.com/user-attachments/assets/89885103-7cbc-43f9-b044-e980e4674a80" />

---

2. Анализ файла `.gitignore`  

**Вопрос:** В каком terraform-файле, согласно `.gitignore`, допустимо сохранить личную, секретную информацию (логины, пароли, ключи, токены и т.д.)?

**Ответ:**  
Согласно файлу `.gitignore`, секретную информацию допустимо сохранять в файле **`personal.auto.tfvars`**.  
Файлы с расширением `.auto.tfvars` автоматически подгружаются Terraform при выполнении команд, но имя `personal.auto.tfvars` явно указано в `.gitignore`, что предотвращает случайное попадание секретов в публичный репозиторий GitHub.

---

3. Получение секретного содержимого ресурса `random_password`  
Выполнена команда `terraform apply`. Сгенерированное секретное значение найдено в файле `terraform.tfstate`.

* **Ключ:** `"result"`
* **Значение:** `"ZPYV9fTLh9YyE8iS"`

<img width="672" height="37" alt="Снимок экрана 2026-08-09 212336" src="https://github.com/user-attachments/assets/e324dc7a-1b85-42f7-908c-7cf19fb21761" />

---

4. Намеренно допущенные ошибки и их исправление  
Блок кода был раскомментирован. При запуске `terraform validate` выявлены следующие ошибки:

* **`Error: Missing name for resource`** (строка 22):  
   Для блока `resource "docker_image"` не указано имя ресурса (требуется 2 метки: тип и имя).  
   *Исправление:* `resource "docker_image" "nginx"`
* **`Error: Invalid resource name`** (строка 27):  
   Имя ресурса контейнера `"1nginx"` начинается с цифры, что запрещено синтаксисом HCL.  
   *Исправление:* `resource "docker_container" "nginx"`
* **`Error: Reference to undeclared resource`** (строка 29):  
   Использована ссылка на несуществующий ресурс `random_password.random_string_FAKE` и атрибут `.resulT` в верхнем регистре.  
   *Исправление:* `random_password.random_string.result`

<img width="780" height="442" alt="Снимок экрана 2026-08-09 213002" src="https://github.com/user-attachments/assets/4b9a957c-f243-4a64-86a5-73007e87f42d" />

После исправления ошибок команда `terraform validate` завершилась успешно:

<img width="520" height="51" alt="Снимок экрана 2026-08-09 213045" src="https://github.com/user-attachments/assets/066493d0-6fb8-4ab3-84e9-12501acc38c0" />

---

5. Применение исправленного кода  
Код применен командой `terraform apply -auto-approve`. Запущенный контейнер проверен с помощью `docker ps`:

<img width="966" height="54" alt="Снимок экрана 2026-08-09 213154" src="https://github.com/user-attachments/assets/07d779d1-8a56-40ae-a95b-91d3426350e9" />

---

6. Изменение имени контейнера и работа с флагом `-auto-approve`  
Имя контейнера в `main.tf` изменено на `"hello_world"`. Изменения применены командой `terraform apply -auto-approve`.

<img width="872" height="53" alt="Снимок экрана 2026-08-09 213551" src="https://github.com/user-attachments/assets/aad71e4f-b177-4321-ba6d-e5e7b9146ba6" />

**Ответы на вопросы:**
* **В чём опасность ключа `-auto-approve`?**  
   Флаг автоматически подтверждает все изменения без показа интерактивного плана и запроса ручного подтверждения (`yes`). В случае ошибки в коде или случайного удаления критического ресурса (например БД) оператор не успеет отменить действие.
* **Зачем пригодится этот ключ?**  
   Ключ необходим при автоматизации развертывания инфраструктуры в CI/CD пайплайнах (GitHub Actions, GitLab CI и др.), где нет терминала и некому вручную ввести `yes`.

---

7. Уничтожение ресурсов  
Все ресурсы уничтожены командой `terraform destroy -auto-approve`. Содержимое `terraform.tfstate` подтверждает удаление ресурсов:

<img width="542" height="174" alt="Снимок экрана 2026-08-09 213722" src="https://github.com/user-attachments/assets/e93e2d98-5cd8-4bcf-bcbe-eb89fe5e0567" />

---

8. Причина сохранения docker-образа `nginx:latest`  
Docker-образ `nginx:latest` не был удален при выполнении `terraform destroy`, так как в коде `main.tf` для ресурса `docker_image` был установлен параметр `keep_locally = true`:

```hcl
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}
```

**Строчка из документации провайдера [`kreuzwerker/docker`](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image):**

<img width="676" height="101" alt="Снимок экрана 2026-08-09 214251" src="https://github.com/user-attachments/assets/ec993caa-b936-4171-b7f5-8346d68389c8" />

## Задание 2* (Дополнительное)

1. Создание ВМ в Yandex Cloud  
В облаке Yandex Cloud с помощью Terraform создана виртуальная машина `docker-vm` (Ubuntu 24.04 LTS, IP: `51.250.84.16`).

---

2. Установка Docker  
На ВМ установлен Docker Engine и пользователю `ubuntu` предоставлены права на управление контейнерами без `sudo`.

---

3. Настройка подключения Terraform к Remote Docker Context по SSH  
Согласно документации провайдера [`kreuzwerker/docker`](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs#remote-hosts), для управления удаленным Docker-демоном через SSH в блоке `provider "docker"` указывается аргумент `host` с префиксом `ssh://` и параметры SSH:

```hcl
provider "docker" {
  host = "ssh://ubuntu@51.250.84.16:22"
  ssh_opts = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null"
  ]
}
```

<img width="704" height="507" alt="Снимок экрана 2026-08-09 232547" src="https://github.com/user-attachments/assets/f99d2e18-f845-4539-9e48-c7298019900b" />

---

4. Развертывание контейнера MySQL 8 через Terraform  
В конфигурации описаны ресурсы генерации паролей `random_password`, скачивание образа `mysql:8` и запуск контейнера с передачей сгенерированных секретов через переменные окружения. Контейнер опубликован на порту `127.0.0.1:3306`.

```hcl
resource "random_password" "mysql_root_password" {
  length      = 16
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "random_password" "mysql_user_password" {
  length      = 16
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "docker_image" "mysql" {
  name         = "mysql:8"
  keep_locally = true
}

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
```

---

5. Проверка ENV-переменных внутри контейнера на ВМ  
После выполнения `terraform apply` выполнено подключение к удаленной ВМ по SSH и выведены переменные окружения запущенного контейнера `mysql_server`:

<img width="468" height="237" alt="Снимок экрана 2026-08-09 233519" src="https://github.com/user-attachments/assets/b98cf669-672f-4a15-8c30-b659429d4d5e" />
