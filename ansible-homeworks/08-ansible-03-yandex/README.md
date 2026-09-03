# Домашнее задание к занятию 3 «Использование Ansible»

## Подготовка к выполнению

### 1. Развертывание хостов в Yandex Cloud
В Yandex Cloud были созданы три виртуальные машины на базе ОС **AlmaLinux 9**:
* `clickhouse` (2 vCPU, 4 ГБ RAM, 20 ГБ HDD, IP: `89.169.143.33`)
* `vector` (2 vCPU, 2 ГБ RAM, 15 ГБ HDD, IP: `51.250.82.75`)
* `lighthouse` (2 vCPU, 2 ГБ RAM, 15 ГБ HDD, IP: `93.77.184.23`)

![Image](task_1_screenshot_1)

### 2. Настройка inventory и проверка доступности хостов
Файл `playbook/inventory/prod.yml` был актуализирован реальными IP-адресами виртуальных машин в Yandex Cloud.

Проведена проверка сетевой доступности хостов с помощью модуля `ping`:
```bash
ansible -i inventory/prod.yml all -m ping
```

![Image](task_2_screenshot_1)

### 3. Линтинг плейбука (ansible-lint)
Плейбук `site.yml` был проверен утилитой `ansible-lint`:
```bash
ansible-lint site.yml
```
Проверка успешно пройдена без ошибок и предупреждений.

![Image](task_5_screenshot_1)

### 4. Тестовый запуск с флагом --check
Выполнен пробный запуск сценария в режиме симуляции:
```bash
ansible-playbook -i inventory/prod.yml site.yml --check
```
Как и ожидалось, на шаге установки пакетов ClickHouse модуль `dnf` завершился с ошибкой отсутствия файлов в `/tmp`. Это связано с тем, что в режиме dry-run предшествующий модуль `get_url` лишь имитирует загрузку дистрибутивов без их фактического сохранения на диск целевого хоста.

![Image](task_6_screenshot_1)

### 5. Применение плейбука с флагом --diff
Плейбук был успешно применен на окружении `prod.yml`:
```bash
ansible-playbook -i inventory/prod.yml site.yml --diff
```
В ходе выполнения:
1. На хосте `clickhouse-01` установлены пакеты ClickHouse, запущена служба и создана база данных `logs`.
2. На хосте `vector-01` скачан и распакован бинарный дистрибутив Vector, развернут systemd-сервис и конфигурационный файл, служба запущена и добавлена в автозагрузку.
3. На хосте `lighthouse-01` установлен веб-сервер Nginx, скачана и распакована веб-статика LightHouse, настроена конфигурация виртуального хоста и запущен Nginx.

Результат выполнения (PLAY RECAP):  
![Image](task_7_screenshot_1)

Проверка доступности веб-интерфейса LightHouse через браузер по внешнему IP (`http://93.77.184.23/`):  
![Image](task_7_screenshot_2)

### 6. Проверка идемпотентности (--diff)
Был выполнен повторный запуск плейбука для подтверждения идемпотентности:
```bash
ansible-playbook -i inventory/prod.yml site.yml --diff
```
Все задачи вернули статус `ok`, количество изменений `changed=0` по всем хостам.

![Image](task_8_screenshot_1)

---

## Описание Playbook

Данный Ansible Playbook (`playbook/site.yml`) предназначен для автоматизированного развертывания и настройки аналитического стека на трех независимых хостах:
1. **ClickHouse** - колоночная аналитическая СУБД (загрузка RPM-пакетов, установка через dnf, запуск службы `clickhouse-server`, создание базы данных `logs`).
2. **Vector** - агент сбора, трансформации и маршрутизации логов (загрузка и распаковка бинарного архива, деплой конфигурации через Jinja2-шаблоны, запуск systemd-сервиса).
3. **LightHouse** - легковесный веб-интерфейс для ClickHouse (установка Nginx, скачивание и распаковка веб-статики из официального репозитория, настройка виртуального хоста Nginx, запуск веб-сервера).

---

## Структура каталогов

```text
playbook/
├── group_vars/
│   ├── clickhouse/
│   │   └── vars.yml          # Переменные для группы clickhouse
│   ├── lighthouse/
│   │   └── vars.yml          # Переменные для группы lighthouse
│   └── vector/
│       └── vars.yml          # Переменные для группы vector
├── inventory/
│   └── prod.yml              # Описание целевых хостов и групп
├── templates/
│   ├── lighthouse.conf.j2    # Jinja2-шаблон конфигурации виртуального хоста Nginx для LightHouse
│   ├── nginx.conf.j2         # Jinja2-шаблон основной конфигурации Nginx
│   ├── vector.service.j2     # Jinja2-шаблон systemd unit-файла для Vector
│   └── vector.yaml.j2        # Jinja2-шаблон конфигурационного файла Vector
├── .gitignore
└── site.yml                  # Главный плейбук со сценариями установки
```

---

## Параметры и переменные

### Группа `clickhouse` (`group_vars/clickhouse/vars.yml`)

| Переменная | Описание | Значение по умолчанию |
|---|---|---|
| `clickhouse_version` | Версия устанавливаемых пакетов ClickHouse | `"22.3.3.44"` |
| `clickhouse_packages` | Список устанавливаемых компонентов | `clickhouse-client`, `clickhouse-server`, `clickhouse-common-static` |

### Группа `vector` (`group_vars/vector/vars.yml`)

| Переменная | Описание | Значение по умолчанию |
|---|---|---|
| `vector_version` | Версия Vector для загрузки из официального репозитория | `"0.38.0"` |
| `vector_config_dir` | Директория для размещения конфигурационных файлов | `"/etc/vector"` |
| `vector_data_dir` | Директория для хранения локальных данных Vector | `"/var/lib/vector"` |

### Группа `lighthouse` (`group_vars/lighthouse/vars.yml`)

| Переменная | Описание | Значение по умолчанию |
|---|---|---|
| `lighthouse_version` | Ветка или релиз репозитория LightHouse | `"master"` |
| `lighthouse_url` | URL-адрес архива с исходным кодом веб-интерфейса | `"https://github.com/VKCOM/lighthouse/archive/refs/heads/master.tar.gz"` |
| `lighthouse_dir` | Директория размещения статических файлов на сервере | `"/var/www/lighthouse"` |
| `lighthouse_port` | TCP-порт для входящих HTTP-подключений веб-сервера | `80` |
| `lighthouse_server_name` | Значение директивы `server_name` в Nginx | `"_"` |

---

## Теги (Tags)

Playbook снабжен тегами для выборочного запуска плеев:

| Тег | Назначение |
|---|---|
| `clickhouse` | Запуск сценария установки, запуска и инициализации СУБД ClickHouse |
| `vector` | Запуск сценария скачивания, установки, конфигурации и старта сервиса Vector |
| `lighthouse` | Запуск сценария установки Nginx, загрузки статики и конфигурации веб-интерфейса LightHouse |

Пример запуска сценария только для LightHouse:
```bash
ansible-playbook -i inventory/prod.yml site.yml --tags lighthouse
```