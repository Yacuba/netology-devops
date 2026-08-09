# Домашнее задание к занятию «Введение в Terraform»

## Чек-лист готовности

1. Установлен Terraform (версия `v1.15.8`).
2. Скачан исходный код из git-репозитория в директорию `01/src`.
3. Установлен и запущен **Docker Engine**.

![01_versions_screenshot]

---

## Задание 1

1. Инициализация проекта
В файле `main.tf` скорректировано ограничение версии `required_version = ">= 1.12.0"`. Выполнена команда `terraform init`, скачавшая необходимые провайдеры (`kreuzwerker/docker` и `hashicorp/random`).

![02_terraform_init_screenshot]

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

![03_terraform_state_secret_screenshot]

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

![04_terraform_mistakes_screenshot]

После исправления ошибок команда `terraform validate` завершилась успешно:

![04_terraform_validate_screenshot]

---

5. Применение исправленного кода
Код применен командой `terraform apply -auto-approve`. Запущенный контейнер проверен с помощью `docker ps`:

![05_docker_ps_first_container_screenshot]

---

6. Изменение имени контейнера и работа с флагом `-auto-approve`
Имя контейнера в `main.tf` изменено на `"hello_world"`. Изменения применены командой `terraform apply -auto-approve`.

![06_docker_ps_hello_world_screenshot]

**Ответы на вопросы:**
* **В чём опасность ключа `-auto-approve`?**  
   Флаг автоматически подтверждает все изменения без показа интерактивного плана и запроса ручного подтверждения (`yes`). В случае ошибки в коде или случайного удаления критического ресурса (например БД) оператор не успеет отменить действие.
* **Зачем пригодится этот ключ?**  
   Ключ необходим при автоматизации развертывания инфраструктуры в CI/CD пайплайнах (GitHub Actions, GitLab CI и др.), где нет терминала и некому вручную ввести `yes`.

---

7. Уничтожение ресурсов
Все ресурсы уничтожены командой `terraform destroy -auto-approve`. Содержимое `terraform.tfstate` подтверждает удаление ресурсов:

![07_terraform_tfstate_empty_screenshot]

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

![08_docker_provider_doc_screenshot]