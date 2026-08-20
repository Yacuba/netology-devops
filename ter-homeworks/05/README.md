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

