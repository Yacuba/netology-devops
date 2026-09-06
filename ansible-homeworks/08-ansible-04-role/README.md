# Домашнее задание к занятию 4 «Работа с roles»

## Подготовка к выполнению

### Настройка SSH-доступа и создание репозиториев для ролей
В рамках подготовки к переносу конфигураций в отдельные роли на GitHub были созданы два публичных пустых репозитория:
* [vector-role](https://github.com/Yacuba/vector-role) - роль для установки и настройки агента сбора логов Vector.
* [lighthouse-role](https://github.com/Yacuba/lighthouse-role) - роль для развертывания веб-интерфейса LightHouse и веб-сервера Nginx.

Была выполнена проверка аутентификации по публичному SSH-ключу к GitHub, а также подтверждено наличие созданных репозиториев через GitHub API:
```bash
ssh -T git@github.com ; \
curl -s https://api.github.com/users/Yacuba/repos | grep '"name": ".*-role"'
```

![Image](task_1_screenshot_1)

---

## Основная часть

### 1. Создание файла зависимостей requirements.yml
В каталоге `playbook` был создан файл `requirements.yml` с описанием зависимости внешней роли ClickHouse:

```yaml
---
- src: git@github.com:AlexeySetevoi/ansible-clickhouse.git
  scm: git
  version: "1.13"
  name: clickhouse
```

### 2. Загрузка роли ClickHouse с помощью ansible-galaxy
Установка описанной в `requirements.yml` роли выполнена с помощью утилиты `ansible-galaxy` в локальную директорию `roles`:

```bash
ansible-galaxy install -r requirements.yml -p roles && ls -la roles/clickhouse/
```

Роль версии `1.13` была успешно скачана и распакована в каталог `playbook/roles/clickhouse`.

![Image](task_2_screenshot_1)

### 3. Инициализация роли vector-role
С помощью команды `ansible-galaxy role init vector-role` был сформирован стандартный каркас роли внутри каталога `playbook/roles/`.

### 4. Перенос задач и разделение переменных
На основе задач из исходного плейбука было выполнено разделение логики и параметров:
* **`defaults/main.yml`** - пользовательские переменные, доступные для переопределения (`vector_version`, `vector_config_dir`, `vector_data_dir`).
* **`vars/main.yml`** - внутренние константы и служебные пути (`vector_install_dir`, `vector_bin_path`, `vector_service_path`, `vector_package_arch`, `vector_archive`, `vector_url`).
* **`tasks/main.yml`** - последовательность шагов по созданию директорий, загрузке и распаковке дистрибутива, созданию симлинка, шаблонизации конфигураций и запуску сервиса.
* **`handlers/main.yml`** - обработчик перезапуска службы с перезагрузкой systemd-демона (`systemctl daemon-reload`).

### 5. Перенос шаблонов
В директорию `roles/vector-role/templates/` перенесены Jinja2-шаблоны:
* `vector.service.j2` - unit-файл для systemd.
* `vector.yaml.j2` - базовый конфигурационный файл с источником демо-логов и выводом в консоль.

Структура созданной роли:

![Image](task_3_screenshot_1)

### 6. Создание, тестирование и публикация роли vector-role
В корне роли был создан подробный `README.md`, описывающий назначение, требования, переменные по умолчанию и пример вызова плейбука.

Перед публикацией роль прошла валидацию:
1. Проверка синтаксиса утилитой `ansible-lint`.
2. Тестовый прогон на реальной виртуальной машине `vector-01` - сервис успешно перешел в статус `active (running)`.
3. Проверка идемпотентности - повторный запуск вернул `changed=0`.

После успешного тестирования роль была закоммичена, помечена семантическим тегом `1.0.0` и опубликована в удаленном репозитории GitHub:
```bash
git init -b main
git add .
git commit -m "feat: initial release of vector-role"
git tag -a "1.0.0" -m "Release version 1.0.0"
git remote add origin git@github.com:Yacuba/vector-role.git
git push -u origin main --tags
```

![Image](task_4_screenshot_1)

### 7. Создание, тестирование и публикация роли lighthouse-role
По правилу «одна роль настраивает один продукт» логика была строго разделена:
* **Роль `lighthouse-role`** отвечает непосредственно за развертывание веб-приложения LightHouse (создание рабочего каталога `/var/www/lighthouse`, загрузка и распаковка исходников, назначение прав и SELinux-контекста, деплой конфигурации виртуального хоста Nginx).
* **Внешние зависимости роли** (EPEL-репозиторий, установка пакетов Nginx и Git, основной конфигурационный файл `nginx.conf`) вынесены на уровень плейбука в блок `pre_tasks`.

Структура каталогов роли:

![Image](task_5_screenshot_1)

Разделение конфигураций:
* **`defaults/main.yml`** - переопределяемые параметры (`lighthouse_version`, `lighthouse_url`, `lighthouse_dir`, `lighthouse_port`, `lighthouse_server_name`).
* **`vars/main.yml`** - системные константы роли (`lighthouse_archive_dest`, `lighthouse_nginx_conf_dest`, `lighthouse_user`, `lighthouse_group`).
* **`templates/lighthouse.conf.j2`** - Jinja2-шаблон конфигурации виртуального хоста Nginx.
* **`README.md`** - документация с описанием переменных и примером вызова.

Прогон тестового сценария завершился успешно:
1. Веб-сервер Nginx запущен и возвращает HTTP-ответ `200 OK`.
2. Повторный запуск плейбука подтвердил полную идемпотентность сценария (`changed=0`).

Роль была закоммичена, помечена тегом `1.0.0` и отправлена в удаленный репозиторий:
```bash
git init -b main
git add .
git commit -m "feat: initial release of lighthouse-role"
git tag -a "1.0.0" -m "Release version 1.0.0"
git remote add origin git@github.com:Yacuba/lighthouse-role.git
git push -u origin main --tags
```

![Image](task_6_screenshot_1)

### 8. Добавление ролей в requirements.yml
Все три роли (внешняя роль ClickHouse и две собственные роли с тегами версии `1.0.0`) были объединены в файле `playbook/requirements.yml`:

```yaml
---
- src: git@github.com:AlexeySetevoi/ansible-clickhouse.git
  scm: git
  version: "1.13"
  name: clickhouse

- src: git@github.com:Yacuba/vector-role.git
  scm: git
  version: "1.0.0"
  name: vector-role

- src: git@github.com:Yacuba/lighthouse-role.git
  scm: git
  version: "1.0.0"
  name: lighthouse-role
```

Загрузка и верификация всех зависимостей из удаленных Git-репозиториев выполнена командой `ansible-galaxy`:
```bash
ansible-galaxy install -r requirements.yml -p roles --force
```

![Image](task_8_screenshot_1)

### 9. Переработка playbook на использование roles и запуск на чистом окружении
Основной сценарий `site.yml` был переработан на модульную архитектуру с использованием ролей и совмещением их с задачами (`pre_tasks` / `post_tasks`):

1. **ClickHouse**:
   * Применена внешняя роль `clickhouse`.
   * Исправлены параметры для AlmaLinux 9: в `group_vars/clickhouse/vars.yml` передан GPG-ключ репозитория (`clickhouse_repo_key`), а в `tasks/install/dnf.yml` роли разрешена установка неподписанных пакетов (`disable_gpg_check: true`).
   * В блоке `post_tasks` реализовано создание базы данных `logs` (`clickhouse-client -h 127.0.0.1 -q 'create database logs;'`).
2. **Vector**:
   * Применена роль `vector-role` (версия `1.0.0`).
3. **LightHouse**:
   * В блоке `pre_tasks` подготавливаются системные зависимости: перевод SELinux в режим permissive, подключение EPEL, установка веб-сервера Nginx и Git, создание необходимых директорий `/etc/nginx/conf.d`, деплой основного конфига `nginx.conf` и запуск службы.
   * Вызывается роль `lighthouse-role` (версия `1.0.0`) для размещения веб-статики и конфигурации виртуального хоста.

#### Проверка качества кода (ansible-lint):
Плейбук прошел линтинг без замечаний:
```bash
ansible-lint site.yml
```

![Image](task_9_screenshot_1)

#### Применение плейбука:
Для исключения влияния артефактов предыдущих тестов виртуальные машины в Yandex Cloud были пересозданы с нуля. Плейбук успешно применился ко всему окружению:
```bash
ansible-playbook -i inventory/prod.yml site.yml
```

![Image](task_9_screenshot_2)

#### Проверка идемпотентности:
Повторный запуск плейбука подтвердил отсутствие повторных изменений (`changed=0` по всем хостам):
```bash
ansible-playbook -i inventory/prod.yml site.yml
```

![Image](task_9_screenshot_3)

#### Проверка работоспособности через веб-интерфейс:
Для подтверждения интеграции компонентов веб-интерфейс LightHouse был открыт в браузере по внешнему IP-адресу хоста `lighthouse-01`. 

В интерфейсе настроено подключение к HTTP-интерфейсу СУБД ClickHouse (`http://<CLICKHOUSE_IP>:8123`), проверено соединение и запрошен список баз данных.

![Image](task_9_screenshot_4)