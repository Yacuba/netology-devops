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
# Шаблонизация cloud-init
data "template_file" "cloudinit" {
  template = file("${path.module}/cloud-init.yml")
  vars = {
    ssh_public_key = var.vms_ssh_root_key
  }
}

# ВМ проекта marketing
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

# ВМ проекта analytics
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
![SSH подключение и проверка nginx](task_1_screenshot_1)<br>

2. Метки (labels) виртуальных машин в консоли Yandex Cloud:  
![Метки ВМ analytics в консоли YC](task_1_screenshot_2)<br>
![Метки ВМ marketing в консоли YC](task_1_screenshot_3)<br>

3. Вывод состояния модуля `module.marketing_vm` в `terraform console`:  
![Вывод terraform console](task_1_screenshot_4)<br>

---

