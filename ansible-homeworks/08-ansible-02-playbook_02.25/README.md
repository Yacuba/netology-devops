# Домашнее задание к занятию 2 «Работа с Playbook»

---

## Описание Playbook

Данный Ansible Playbook (`playbook/site.yml`) предназначен для автоматизированного развертывания и базовой конфигурации двух компонентов инфраструктуры:
1. **ClickHouse** — колоночная аналитическая СУБД (установка RPM-пакетов, запуск сервиса, создание базы данных `logs`).
2. **Vector** — агент сбора, трансформации и маршрутизации логов (загрузка и распаковка бинарного архива, деплой конфигурации через Jinja2-шаблон, создание и запуск systemd-сервиса).

---

## Структура каталогов

```text
playbook/
├── group_vars/
│   ├── clickhouse/
│   │   └── vars.yml          # Переменные для группы clickhouse
│   └── vector/
│       └── vars.yml          # Переменные для группы vector
├── inventory/
│   └── prod.yml              # Описание целевых хостов и групп
├── templates/
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

---

## Теги (Tags)

Playbook снабжен тегами для выборочного запуска плеев:

| Тег | Назначение |
|---|---|
| `clickhouse` | Запуск сценария установки, запуска и инициализации СУБД ClickHouse |
| `vector` | Запуск сценария скачивания, установки, конфигурации и старта сервиса Vector |

Пример запуска только настройки Vector:
```bash
ansible-playbook -i inventory/prod.yml site.yml --tags vector
```

---

## Выполнение заданий и результаты

### Задание 5. Проверка Playbook с помощью `ansible-lint`

Команда запуска проверки синтаксиса и лучших практик Ansible:
```bash
ansible-lint site.yml
```

Линтер успешно прошел валидацию без ошибок и предупреждений (`0 failure(s), 0 warning(s)`):

<img width="966" height="51" alt="Снимок экрана 2026-09-01 175254" src="https://github.com/user-attachments/assets/915431ef-4b81-402b-9481-e52b15ea376b" />

---

### Задание 6. Запуск Playbook с флагом `--check`

Команда запуска в режиме симуляции (dry-run):
```bash
ansible-playbook -i inventory/prod.yml site.yml --check
```

В режиме dry-run модули загрузки файлов (`get_url`) не сохраняют бинарные артефакты на диск физически. Из-за этого последующая задача пакетного менеджера (`dnf`) сообщает об отсутствии локальных RPM-файлов на хосте. Это ожидаемое поведение Ansible при проверке зависимых цепочек задач:

<img width="1477" height="571" alt="Снимок экрана 2026-09-01 175806" src="https://github.com/user-attachments/assets/43fc9c96-4175-48ca-9773-737f64ef2076" />

---

### Задание 7. Запуск Playbook на боевом окружении (`prod.yml`) с флагом `--diff`

Команда запуска для применения изменений:
```bash
ansible-playbook -i inventory/prod.yml site.yml --diff
```

Все задачи успешно выполнены. ClickHouse и Vector установлены, сконфигурированы и запущены. Механизм `block/rescue` штатно перехватил платформозависимый пакет ClickHouse (`rescued=1`), а хэндлеры применили конфигурацию:

<img width="829" height="202" alt="Снимок экрана 2026-09-01 182042" src="https://github.com/user-attachments/assets/d6ba88b5-e685-44d8-aef1-0e6b47481eaf" />

---

### Задание 8. Повторный запуск Playbook с флагом `--diff` (Проверка идемпотентности)

Команда повторного запуска:
```bash
ansible-playbook -i inventory/prod.yml site.yml --diff
```

Playbook полностью идемпотентен: повторный прогон завершился со статусом `changed=0` и `failed=0` для всех хостов инвентаря:

<img width="813" height="372" alt="Снимок экрана 2026-09-01 182257" src="https://github.com/user-attachments/assets/24d8d83b-2726-4206-889f-2dd13ccd773f" />
