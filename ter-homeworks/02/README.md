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
<img width="842" height="148" alt="Снимок экрана 2026-08-13 163825" src="https://github.com/user-attachments/assets/e877a9b6-f9d5-4966-b79f-cb09e57686e6" />  <br>
   * **Причина**: Опечатка в наименовании платформы (написано `standart` вместо `standard`), а также указание несуществующей версии `v4`.
   * **Решение**: Название платформы изменено на `standard-v3`.  
<img width="881" height="464" alt="Снимок экрана 2026-08-13 163907" src="https://github.com/user-attachments/assets/7b79ff9a-8f12-4780-a3d5-2bb703429c6d" />  <br>

2. **Ошибка доли ЦПУ (`specified core fraction is not available on platform...`)**:  
<img width="848" height="143" alt="Снимок экрана 2026-08-13 164253" src="https://github.com/user-attachments/assets/9ab91099-9297-4a71-adf0-548a966b139d" />  <br>
   * **Причина**: Несовместимость комбинации выбранной платформы и параметра `core_fraction`. Платформа `standard-v3` требует `core_fraction` не менее 20%.
   * **Решение**: Указано значение 20% для `standard-v3`.

3. **Ошибка количества ядер (`specified number of cores is not available... allowed core number: 2, 4`)**:  
<img width="839" height="148" alt="Снимок экрана 2026-08-13 164513" src="https://github.com/user-attachments/assets/ffd05d5e-e273-476f-ae51-c223f9908e9c" />  <br>
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
   <img width="511" height="130" alt="Снимок экрана 2026-08-13 170040" src="https://github.com/user-attachments/assets/9d746cc4-f8e6-442a-93a1-bd9ebb6e1339" />

2. **Результат выполнения команды `curl ifconfig.me` внутри ВМ по SSH:**  
   <img width="390" height="40" alt="Снимок экрана 2026-08-13 170133" src="https://github.com/user-attachments/assets/0bee85f5-d2fe-48c4-a8c0-1fd6dfd9e84c" />

---

## Задание 2

1. Хардкод-значения для `yandex_compute_image` и `yandex_compute_instance` заменены на переменные с префиксом `vm_web_` в файле `variables.tf`.
2. Для всех объявленных переменных явно указаны типы данных (`string`, `number`).
3. Выполнена проверка командой `terraform plan`. Изменения в инфраструктуре отсутствуют (`No changes. Your infrastructure matches the configuration.`).  
<img width="902" height="66" alt="Снимок экрана 2026-08-13 174412" src="https://github.com/user-attachments/assets/d46051f3-3845-494f-8a9f-bd6b493d2ad8" />

---

## Задание 3

1. В корне проекта создан файл `vms_platform.tf`. В него перенесены переменные первой ВМ (`vm_web_...`).
2. Объявлены переменные для второй ВМ с префиксом `vm_db_` (`vm_db_cores = 2`, `vm_db_memory = 2`, `vm_db_core_fraction = 20`, `vm_db_zone = "ru-central1-b"`).
3. В файле `main.tf` создана подсеть для зоны `ru-central1-b` и описан ресурс ВМ `netology-develop-platform-db`.
4. Изменения успешно применены (`terraform apply`).  
<img width="878" height="106" alt="Снимок экрана 2026-08-13 181200" src="https://github.com/user-attachments/assets/19e8adb1-8386-469e-94a3-e6c8cdd7123f" />

---

## Задание 4

1. В файле `outputs.tf` объявлен единый output `vms_info`, возвращающий имя, внешний IP-адрес и FQDN для каждой виртуальной машины.
2. Вывод команды `terraform output`:  
<img width="479" height="244" alt="Снимок экрана 2026-08-13 182240" src="https://github.com/user-attachments/assets/33a7a10f-288e-475a-8c36-ca345b53d6af" />

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
<img width="511" height="148" alt="Снимок экрана 2026-08-13 215428" src="https://github.com/user-attachments/assets/805b3c5e-4109-4525-a409-434516466f01" />  <br>
4. Выполнено подключение к серийной консоли через SSH-шлюз (`serialssh.cloud.yandex.net:9600`) и проверен доступ в сеть:

<img width="453" height="308" alt="Снимок экрана 2026-08-13 222305" src="https://github.com/user-attachments/assets/dc66dad9-e825-44ec-8866-cd56415c976c" />  <br>

При последовательных запросах `curl ifconfig.me` возвращаются разные публичные IP-адреса, так как режим `shared_egress_gateway` распределяет исходящие TCP-сессии через динамический пул исходящих адресов Yandex Cloud.
