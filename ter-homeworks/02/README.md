# Домашнее задание к занятию «Основы Terraform. Yandex Cloud»

## Задание 1

### Подготовка окружения
1. Создан сервисный аккаунт `yc-sa`, сгенерирован авторизационный ключ `~/.authorized_key.json` и назначена роль `editor` на каталог:
   ```bash
   yc iam service-account create --name yc-sa
   yc iam key create --service-account-name yc-sa --output ~/.authorized_key.json
   yc resource-manager folder add-access-binding --id $(yc config get folder-id) --role editor --service-account-name yc-sa
   yc config unset token
   yc config set service-account-key ~/.authorized_key.json
   ```

2. Сгенерирована SSH-пара ключей. Публичная часть добавлена в файл `terraform.tfvars`.

---

### Анализ и исправление ошибок в коде Terraform

При последовательном запуске манифеста были выявлены и исправлены следующие синтаксические и логические ошибки:

1. **Ошибка платформы (`Platform "standart-v4" not found`)**:  
![Ошибка Platform "standart-v4" not found](task_1_screenshot_1)
   * **Причина**: Опечатка в наименовании платформы (написано `standart` вместо `standard`), а также указание несуществующей версии `v4`.
   * **Решение**: Название платформы изменено на `standard-v3`.  
![Стандартные платформы Yandex Cloud](task_1_screenshot_2)

2. **Ошибка доли ЦПУ (`specified core fraction is not available on platform...`)**:  
![Ошибка core fraction](task_1_screenshot_3)
   * **Причина**: Несовместимость комбинации выбранной платформы и параметра `core_fraction`. Платформа `standard-v3` требует `core_fraction` не менее 20%.
   * **Решение**: Указано значение 20% для `standard-v3`.

3. **Ошибка количества ядер (`specified number of cores is not available... allowed core number: 2, 4`)**:  
![Ошибка core number](task_1_screenshot_4)
   * **Причина**: В исходном манифесте было указано `cores = 1`. API Yandex Cloud требует минимум 2 vCPU для Compute-ресурсов.
   * **Решение**: Количество ядер изменено на `cores = 2`.

---

### Ответы на вопросы задания

1. **Зачем нужен параметр `preemptible = true`?**
   * Создает прерываемую виртуальную машину. Такая ВМ работает не более 24 часов и может быть принудительно остановлена Yandex Cloud при недостатке ресурсов. Это даёт скидку на Compute-ресурсы до 70-80%.

2. **Зачем нужен параметр `core_fraction` (например, `5` или `20`)?**
   * Задает гарантированную долю процессорного времени vCPU в процентах. Позволяет не переплачивать за 100% мощности процессора, если ВМ не несет постоянной высокой нагрузки. Снижает стоимость аренды.

---

### Результаты выполнения

1. **Виртуальная машина в консоли Yandex Cloud:**  
   ![Виртуальная машина в Yandex Cloud](task_1_screenshot_5)

2. **Результат выполнения команды `curl ifconfig.me` внутри ВМ по SSH:**  
   ![Подключение по SSH и curl ifconfig.me](task_1_screenshot_6)

---

## Задание 2

1. Хардкод-значения для `yandex_compute_image` и `yandex_compute_instance` заменены на переменные с префиксом `vm_web_` в файле `variables.tf`.
2. Для всех объявленных переменных явно указаны типы данных (`string`, `number`).
3. Выполнена проверка командой `terraform plan`. Изменения в инфраструктуре отсутствуют (`No changes. Your infrastructure matches the configuration.`).  
![no changes are needed](task_2_screenshot_1)

---

## Задание 3

1. В корне проекта создан файл `vms_platform.tf`. В него перенесены переменные первой ВМ (`vm_web_...`).
2. Объявлены переменные для второй ВМ с префиксом `vm_db_` (`vm_db_cores = 2`, `vm_db_memory = 2`, `vm_db_core_fraction = 20`, `vm_db_zone = "ru-central1-b"`).
3. В файле `main.tf` создана подсеть для зоны `ru-central1-b` и описан ресурс ВМ `netology-develop-platform-db`.
4. Изменения успешно применены (`terraform apply`).  
![creating a new VM](task_3_screenshot_1)

---

## Задание 4

1. В файле `outputs.tf` объявлен единый output `vms_info`, возвращающий имя, внешний IP-адрес и FQDN для каждой виртуальной машины.
2. Вывод команды `terraform output`:  
![terraform output](task_4_screenshot_1)

---

## Задание 5

1. В файле `locals.tf` создан единый local-блок, формирующий имена ВМ с помощью интерполяции нескольких переменных (`local.company`, `local.env`, `local.web_type`).
2. В файле `main.tf` значения параметров `name` ресурсов ВМ заменены на `local.vm_web_name` и `local.vm_db_name`.
3. Изменения проверены с помощью `terraform plan`. Имена ВМ остались прежними, инфраструктура не требует изменений.

---

## Задание 6

1. В файле `vms_platform.tf` закомментированы неиспользуемые переменные ресурсов и создана единая map-переменная `vms_resources` типа `map(object)` с конфигурацией ресурсов (ядра, память, доля vCPU, размер и тип диска) для обеих ВМ.
2. Создана общая переменная `metadata` типа `map(string)`, включающая параметры включения серийного порта и открытый SSH-ключ.
3. Значения переменных `vms_resources` и `metadata` заданы в файле `terraform.tfvars`.
4. В файле `main.tf` ресурсы обеих ВМ переведены на использование `var.vms_resources` и `var.metadata`.
5. Применен план изменений (`terraform apply`). Виртуальные машины пересозданы с новыми параметрами boot-дисков (размер 10 ГБ, типы `network-hdd` и `network-ssd`).

---

## Задание 7*

В процессе работы с `terraform console` были выполнены следующие команды:

1. **Второй элемент списка `test_list`:**
   ```hcl
   > local.test_list[1]
   "staging"
   ```

2. **Длина списка `test_list`:**
   ```hcl
   > length(local.test_list)
   3
   ```

3. **Значение ключа `admin` из map `test_map`:**
   ```hcl
   > local.test_map.admin
   "John"
   ```

4. **Interpolation-выражение:**
   ```hcl
   > "${local.test_map.admin} is ${keys(local.test_map)[0]} for ${local.test_list[2]} server based on OS ${local.servers[local.test_list[2]].image} with ${local.servers[local.test_list[2]].cpu} vcpu, ${local.servers[local.test_list[2]].ram} ram and ${length(local.servers[local.test_list[2]].disks)} virtual disks"
   "John is admin for production server based on OS ubuntu-20-04 with 10 vcpu, 40 ram and 4 virtual disks"
   ```

---

## Задание 8*

1. **Описание типа переменной `test`:**
   Полный тип переменной для заданной структуры — `list(map(list(string)))`.

   *Объявление переменной в `variables.tf`:*
   ```hcl
   variable "test" {
     type        = list(map(list(string)))
     description = "Task 8* variable"
   }
   ```

2. **Выражение в `terraform console` для вычленения строки SSH-подключения:**
   ```hcl
   > var.test[0]["dev1"][0]
   "ssh -o 'StrictHostKeyChecking=no' ubuntu@62.84.124.117"
   ```

---

## Задание 9*

1. В файле `main.tf` объявлены ресурсы `yandex_vpc_gateway` (NAT-шлюз типа `shared_egress_gateway`) и `yandex_vpc_route_table` с маршрутом `0.0.0.0/0` через созданный шлюз.
2. Таблица маршрутизации привязана к подсетям через аргумент `route_table_id`.
3. У виртуальных машин отключены публичные IP-адреса (`nat = false`).
4. Выполнено подключение к серийной консоли через SSH-шлюз (`serialssh.cloud.yandex.net:9600`) и проверен доступ в сеть:

![Выход в интернет через Serial Console](task_9_screenshot_1)

При последовательных запросах `curl ifconfig.me` возвращаются разные публичные IP-адреса, так как режим `shared_egress_gateway` распределяет исходящие TCP-сессии через динамический пул исходящих адресов Yandex Cloud.