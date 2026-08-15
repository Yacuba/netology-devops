# Домашнее задание к занятию «Управляющие конструкции в коде Terraform»

## Задание 1

1. Изучен проект и подготовлены конфигурационные файлы.
2. В целях безопасной авторизации путь к файлу ключа сервисного аккаунта вынесен в переменную `service_account_key_file` в файле `personal.auto.tfvars`, а его считывание выполняется в `providers.tf`:

   ```hcl
   provider "yandex" {
     service_account_key_file = file(var.service_account_key_file)
     cloud_id                 = var.cloud_id
     folder_id                = var.folder_id
     zone                     = var.default_zone
   }
   ```

3. Выполнена инициализация и применение конфигурации (`terraform init`, `terraform apply`).  

### Результат применения:  
<img width="631" height="142" alt="Снимок экрана 2026-08-15 172234" src="https://github.com/user-attachments/assets/8fa4a935-77bd-4d93-8961-dcfc128b9798" /><br>

### Скриншот правил группы безопасности в консоли Yandex Cloud:

<img width="986" height="519" alt="Снимок экрана 2026-08-15 172041" src="https://github.com/user-attachments/assets/629668d5-80f2-4ce3-b80b-3bff0dad690f" /><br>

---

## Задание 2

1. В файле `locals.tf` настроено считывание публичного SSH-ключа с помощью функции `file` и `pathexpand`, а также сформирован блок метаданных:

   ```hcl
   locals {
     ssh_public_key = file(pathexpand(var.ssh_public_key_path))

     vms_metadata = {
       serial-port-enable = var.serial_port_enable
       ssh-keys           = "${var.ssh_user}:${local.ssh_public_key}"
     }
   }
   ```

2. В файле `variables.tf` описаны переменные для создания виртуальных машин:
   - `web_vm_count`, `web_vm_resources` и префикс имени для веб-серверов.
   - Список объектов `each_vm` для конфигурации баз данных с различными характеристиками CPU, RAM и объема диска:

   ```hcl
    variable "each_vm" {
      type = list(object({
        vm_name       = string
        cpu           = number
        ram           = number
        disk_volume   = number
        core_fraction = number
        platform_id   = string
        preemptible   = bool
        nat           = bool
      }))
      default = [
        {
          vm_name       = "main"
          cpu           = 4
          ram           = 4
          disk_volume   = 15
          core_fraction = 20
          platform_id   = "standard-v3"
          preemptible   = true
          nat           = true
        },
        {
          vm_name       = "replica"
          cpu           = 2
          ram           = 2
          disk_volume   = 10
          core_fraction = 20
          platform_id   = "standard-v3"
          preemptible   = true
          nat           = true
        }
      ]
      description = "Database instances specifications for for_each loop"
    }
   ```

3. В файле `for_each-vm.tf` описано создание двух ВМ баз данных (`main` и `replica`) с помощью мета-аргумента `for_each`:

   ```hcl
    resource "yandex_compute_instance" "db" {
      for_each = { for vm in var.each_vm : vm.vm_name => vm }

      name        = each.value.vm_name
      hostname    = each.value.vm_name
      platform_id = each.value.platform_id
      zone        = var.default_zone

      resources {
        cores         = each.value.cpu
        memory        = each.value.ram
        core_fraction = each.value.core_fraction
      }

      boot_disk {
        initialize_params {
          image_id = data.yandex_compute_image.ubuntu.image_id
          size     = each.value.disk_volume
        }
      }

      scheduling_policy {
        preemptible = each.value.preemptible
      }

      network_interface {
        subnet_id          = yandex_vpc_subnet.develop.id
        nat                = each.value.nat
        security_group_ids = [yandex_vpc_security_group.example.id]
      }

      metadata = {
        serial-port-enable = local.vms_metadata.serial-port-enable
        ssh-keys           = local.vms_metadata.ssh-keys
      }
    }
   ```

4. В файле `count-vm.tf` описано создание двух одинаковых ВМ `web-1` и `web-2` с помощью мета-аргумента `count loop`, группы безопасности и явной зависимости `depends_on = [yandex_compute_instance.db]`:

   ```hcl
    resource "yandex_compute_instance" "web" {
      count = var.web_vm_count

      name        = "${var.web_vm_name_prefix}-${count.index + 1}"
      hostname    = "${var.web_vm_name_prefix}-${count.index + 1}"
      platform_id = var.web_vm_resources.platform_id
      zone        = var.default_zone

      resources {
        cores         = var.web_vm_resources.cores
        memory        = var.web_vm_resources.memory
        core_fraction = var.web_vm_resources.core_fraction
      }

      boot_disk {
        initialize_params {
          image_id = data.yandex_compute_image.ubuntu.image_id
          size     = var.web_vm_resources.disk_size
        }
      }

      scheduling_policy {
        preemptible = var.web_vm_resources.preemptible
      }

      network_interface {
        subnet_id          = yandex_vpc_subnet.develop.id
        nat                = var.web_vm_resources.nat
        security_group_ids = [yandex_vpc_security_group.example.id]
      }

      metadata = {
        serial-port-enable = local.vms_metadata.serial-port-enable
        ssh-keys           = local.vms_metadata.ssh-keys
      }

      depends_on = [yandex_compute_instance.db]
    }
   ```

5. Конфигурация успешно применена. Все виртуальные машины созданы в облаке.  

<img width="720" height="232" alt="Снимок экрана 2026-08-15 202211" src="https://github.com/user-attachments/assets/ee71aa29-7374-4750-aab2-a9e32f8ee485" /><br>

---

## Задание 3

1. В файле `variables.tf` объявлены переменные для управления количеством, размером дополнительных дисков и конфигурацией одиночной ВМ `storage`:

   ```hcl
    ### Storage VM and Disks variables (Task 3)
    variable "storage_disk_count" {
      type        = number
      default     = 3
      description = "Number of secondary disks to create"
    }

    variable "storage_disk_size" {
      type        = number
      default     = 1
      description = "Size of each secondary disk in GB"
    }

    variable "storage_disk_name_prefix" {
      type        = string
      default     = "disk"
      description = "Prefix for storage secondary disk names"
    }

    variable "storage_vm_name" {
      type        = string
      default     = "storage"
      description = "Name for storage VM instance"
    }

    variable "storage_vm_resources" {
      type = object({
        platform_id   = string
        cores         = number
        memory        = number
        core_fraction = number
        disk_size     = number
        preemptible   = bool
        nat           = bool
      })
      default = {
        platform_id   = "standard-v3"
        cores         = 2
        memory        = 1
        core_fraction = 20
        disk_size     = 10
        preemptible   = true
        nat           = true
      }
      description = "Hardware specifications for storage instance"
    }
   ```

2. В файле `disk_vm.tf` описано создание 3 виртуальных дисков с помощью ресурса `yandex_compute_disk` и мета-аргумента `count`, а также создание одиночной ВМ `storage` с подключением этих дисков через динамический блок `dynamic "secondary_disk"`:

   ```hcl
   # 1. Create secondary disks via count loop
   resource "yandex_compute_disk" "storage_disk" {
     count = var.storage_disk_count

     name = "${var.storage_disk_name_prefix}-${count.index + 1}"
     size = var.storage_disk_size
     zone = var.default_zone
   }

   # 2. Create single storage instance with dynamic secondary_disk block
   resource "yandex_compute_instance" "storage" {
     name        = var.storage_vm_name
     hostname    = var.storage_vm_name
     platform_id = var.storage_vm_resources.platform_id
     zone        = var.default_zone

     resources {
       cores         = var.storage_vm_resources.cores
       memory        = var.storage_vm_resources.memory
       core_fraction = var.storage_vm_resources.core_fraction
     }

     boot_disk {
       initialize_params {
         image_id = data.yandex_compute_image.ubuntu.image_id
         size     = var.storage_vm_resources.disk_size
       }
     }

     dynamic "secondary_disk" {
       for_each = yandex_compute_disk.storage_disk
       content {
         disk_id = secondary_disk.value.id
       }
     }

     scheduling_policy {
       preemptible = var.storage_vm_resources.preemptible
     }

     network_interface {
       subnet_id          = yandex_vpc_subnet.develop.id
       nat                = var.storage_vm_resources.nat
       security_group_ids = [yandex_vpc_security_group.example.id]
     }

     metadata = {
       serial-port-enable = local.vms_metadata.serial-port-enable
       ssh-keys           = local.vms_metadata.ssh-keys
     }
   }
   ```

3. Конфигурация успешно применена. Дополнительные диски созданы и смонтированы к виртуальной машине `storage`.  

<img width="975" height="390" alt="Снимок экрана 2026-08-15 204636" src="https://github.com/user-attachments/assets/cf614ab6-e161-4223-a806-85e755edce9a" /><br>

---

## Задание 4

1. Создан файл шаблона `hosts.tftpl` для генерации инвентаря Ansible с поддержкой произвольного количества хостов в каждой из групп (`webservers`, `databases`, `storage`), а также передачей `ansible_host` и `fqdn`:

   ```ini
   [webservers]
   %{ for i in webservers ~}
   ${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"]} fqdn=${i["fqdn"]}
   %{ endfor ~}

   [databases]
   %{ for i in databases ~}
   ${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"]} fqdn=${i["fqdn"]}
   %{ endfor ~}

   [storage]
   %{ for i in storage ~}
   ${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"]} fqdn=${i["fqdn"]}
   %{ endfor ~}
   ```

2. В файле `ansible.tf` с помощью ресурса `local_file` и функции `templatefile` настроено создание инвентаря:

   ```hcl
   resource "local_file" "hosts_cfg" {
     content = templatefile("${path.module}/hosts.tftpl", {
       webservers = yandex_compute_instance.web
       databases  = values(yandex_compute_instance.db)
       storage    = [yandex_compute_instance.storage]
     })
     filename = "${path.module}/hosts.cfg"
   }
   ```

3. Выполнена команда `terraform apply`, сгенерирован итоговый файл `hosts.cfg`:

   ```ini
   [webservers]
   web-1 ansible_host=93.77.176.193 fqdn=web-1.ru-central1.internal
   web-2 ansible_host=89.169.130.118 fqdn=web-2.ru-central1.internal

   [databases]
   main ansible_host=84.201.131.7 fqdn=main.ru-central1.internal
   replica ansible_host=158.160.51.182 fqdn=replica.ru-central1.internal

   [storage]
   storage ansible_host=89.169.140.87 fqdn=storage.ru-central1.internal
   ```

---

## Задание 5*

1. В файле `outputs.tf` описана выходная переменная `vms_info`, которая объединяет виртуальные машины из ресурсов `count` и `for_each` в единый список словарей через генераторы списков и функцию `concat()`:

   ```hcl
   output "vms_info" {
     description = "List of maps containing name, id, and fqdn for count and for_each instances"
     value = concat(
       [
         for vm in yandex_compute_instance.web : {
           name = vm.name
           id   = vm.id
           fqdn = vm.fqdn
         }
       ],
       [
         for vm in values(yandex_compute_instance.db) : {
           name = vm.name
           id   = vm.id
           fqdn = vm.fqdn
         }
       ]
     )
   }
   ```

2. Выполнена команда `terraform output`, результат вывода:  

<img width="324" height="378" alt="Снимок экрана 2026-08-15 213459" src="https://github.com/user-attachments/assets/9f3c00b0-f15c-4fbd-912f-7188127e9ebc" /><br>

---

## Задание 6*

1. Файл шаблона `hosts.tftpl` модифицирован для универсальной поддержки виртуальных машин с публичными адресами и без них (для сценария работы через Bastion-сервер с приватными адресами):

   ```ini
   [webservers]
   %{ for i in webservers ~}
   ${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"] != "" ? i["network_interface"][0]["nat_ip_address"] : i["network_interface"][0]["ip_address"]} fqdn=${i["fqdn"]}
   %{ endfor ~}

   [databases]
   %{ for i in databases ~}
   ${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"] != "" ? i["network_interface"][0]["nat_ip_address"] : i["network_interface"][0]["ip_address"]} fqdn=${i["fqdn"]}
   %{ endfor ~}

   [storage]
   %{ for i in storage ~}
   ${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"] != "" ? i["network_interface"][0]["nat_ip_address"] : i["network_interface"][0]["ip_address"]} fqdn=${i["fqdn"]}
   %{ endfor ~}
   ```

2. Создан тестовый плейбук `test.yml` для проверки доступности хостов через модуль `ansible.builtin.ping`:

   ```yaml
   - name: Test connectivity playbook
     hosts: all
     gather_facts: false
     tasks:
       - name: Ping hosts
         ansible.builtin.ping:
   ```

3. В файле `ansible.tf` описан ресурс `null_resource` с provisioner `local-exec` для автоматического запуска плейбука:

   ```hcl
   resource "null_resource" "web_hosts_provision" {
     depends_on = [
       yandex_compute_instance.web,
       yandex_compute_instance.db,
       yandex_compute_instance.storage,
       local_file.hosts_cfg
     ]

     provisioner "local-exec" {
       command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu -i ${abspath(path.module)}/hosts.cfg ${abspath(path.module)}/test.yml"
       on_failure = continue
       environment = {
         ANSIBLE_HOST_KEY_CHECKING = "False"
       }
     }

    triggers = {
      always_run = timestamp()
    }
   }
   ```

4. Выполнено применение конфигурации с внешними IP. Плейбук успешно подключился ко всем 5 созданным виртуальным машинам.  

<img width="1155" height="233" alt="Снимок экрана 2026-08-15 220610" src="https://github.com/user-attachments/assets/9e15d6cf-de96-44d3-91ab-35dfab969a18" /><br>

5. Для проверки работы шаблона в сценарии Bastion-сервера у всех ВМ были отключены внешние IP-адреса (`nat = false`). Шаблон `hosts.tftpl` корректно подставил внутренние IP-адреса подсети (`10.0.1.X`) в файл `hosts.cfg`.  

<img width="555" height="212" alt="Снимок экрана 2026-08-15 221806" src="https://github.com/user-attachments/assets/0e883661-f72f-4c09-bf0d-d01c9b5997c8" /><br>

---

## Задание 7*

Для удаления 3-го элемента (индекс `2`) из списков `subnet_ids` и `subnet_zones` в переменной `local.vpc` составлено следующее выражение с использованием функции `merge()` и фильтрации `for ... if`:

   ```hcl
   merge(local.vpc, {
     subnet_ids   = [for i, v in local.vpc.subnet_ids : v if i != 2]
     subnet_zones = [for i, v in local.vpc.subnet_zones : v if i != 2]
   })
   ```

<img width="1095" height="243" alt="Снимок экрана 2026-08-15 222844" src="https://github.com/user-attachments/assets/206bfe44-9d93-467f-8fed-f5fd4a6fc7e0" /><br>

---

## Задание 8*

В исходном tpl-шаблоне были допущены две ошибки:

```text
[webservers]
%{~ for i in webservers ~}
${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"] platform_id=${i["platform_id "]}}
%{~ endfor ~}
```

### Диагностика и исправление ошибок:

1. Отсутствовала закрывающая фигурная скобка `}` в блоке `ansible_host=${...`. Terraform зафиксировал ошибку синтаксиса на строке 3 (позиции 85-86):
   > `Call to function "templatefile" failed: hosts_task8.tftpl:3,85-86: Invalid character;`  

   <img width="1245" height="157" alt="Снимок экрана 2026-08-15 223625" src="https://github.com/user-attachments/assets/2002521e-0a07-4b7b-a0f5-7baee40f2543" /><br>

2. В выражении `${i["platform_id "]}` присутствовал лишний пробел на конце ключа. Terraform сообщил о невозможности найти элемент в коллекции на строке 3 (позиции 89-105):
   > `Call to function "templatefile" failed: hosts_task8.tftpl:3,89-105: Invalid index; The given key does not identify an element in this collection value.`  

   <img width="1288" height="128" alt="Снимок экрана 2026-08-15 224219" src="https://github.com/user-attachments/assets/e86182ef-89b8-4838-b0de-d34e68619f5a" /><br>

3. **Исправленный шаблон `hosts_task8.tftpl`:**

   ```ini
   [webservers]
   %{ for i in webservers ~}
   ${i["name"]} ansible_host=${i["network_interface"][0]["nat_ip_address"]} platform_id=${i["platform_id"]}
   %{ endfor ~}
   ```
  
<img width="1227" height="119" alt="Снимок экрана 2026-08-15 224343" src="https://github.com/user-attachments/assets/47194342-a831-4e11-bf54-d80b9b945746" /><br>

---

## Задание 9*

1. Выражение для формирования списка строк от `"rc01"` до `"rc99"` с использованием функций `range` и `format`:

   ```hcl
   [for i in range(1, 100) : format("rc%02d", i)]
   ```

   - `range(1, 100)` генерирует последовательность чисел от 1 до 99.
   - `format("rc%02d", i)` форматирует числа с добавлением префикса и ведущего нуля.

2. Выражение для формирования списка от `"rc01"` до `"rc96"`, исключающего все числа, заканчивающиеся на `"0"`, `"7"`, `"8"`, `"9"`, за исключением `"rc19"`:

   ```hcl
   [for i in range(1, 97) : format("rc%02d", i) if !contains([0, 7, 8, 9], i % 10) || i == 19]
   ```

   - `i % 10` вычисляет последнюю цифру числа.
   - Условие `!contains([0, 7, 8, 9], i % 10)` фильтрует нежелательные окончания.
   - Условие `|| i == 19` принудительно оставляет в списке элемент `"rc19"`.
