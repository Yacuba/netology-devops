# Домашнее задание к занятию 6 «Создание собственных модулей»

## Подготовка к выполнению

1. Создан пустой публичный репозиторий: `my_own_collection`.
   * Ссылка на репозиторий: https://github.com/Yacuba/my_own_collection
2. Клонирован репозиторий Ansible, развернуто виртуальное окружение, установлены зависимости и выполнен скрипт окружения `hacking/env-setup`.

Результат проверки версии Ansible в настроенном окружении:

<img width="798" height="169" alt="Снимок экрана 2026-09-13 123053" src="https://github.com/user-attachments/assets/3f6fdf8f-3952-467f-acc3-3fa748b7f039" />

## Основная часть

### 1. Написание модуля

Разработан собственный модуль `my_own_module.py`, принимающий обязательные параметры `path` и `content`. Модуль реализует логику идемпотентности:
* проверяет наличие файла по указанному пути;
* сверяет текущее содержимое файла с целевым;
* вносит изменения только при отсутствии файла или несовпадении контента;
* поддерживает работу в режиме `check_mode`.

### 2. Локальная проверка модуля на исполняемость

Проверка модуля выполнена локально в активированном окружении разработки с передачей параметров через JSON-файл:

<img width="1444" height="205" alt="Снимок экрана 2026-09-13 125347" src="https://github.com/user-attachments/assets/fb0e23e9-f1c9-471d-9c4b-ac138af4dc25" />

### 3. Single task playbook и проверка идемпотентности

Создан плейбук `playbook.yml` для вызова модуля `my_own_module`.
Выполнена проверка на идемпотентность путем двукратного запуска. При первом запуске файл создается (`changed=1`), при повторном - изменений не происходит (`ok=1, changed=0`).

<img width="875" height="401" alt="Снимок экрана 2026-09-13 130610" src="https://github.com/user-attachments/assets/09cf3406-a77f-4a71-8dd8-d08168c49831" />

### 4. Инициализация коллекции и создание роли

1. Выполнен выход из виртуального окружения (`deactivate`).
2. Инициализирована структура коллекции `my_own_namespace.yandex_cloud_elk`.
3. Модуль `my_own_module.py` перенесен в директорию `plugins/modules/`.
4. Создана роль `site_file`, вызывающая модуль через FQCN `my_own_namespace.yandex_cloud_elk.my_own_module`. В `defaults/main.yml` заданы значения по умолчанию для параметров `site_file_path` и `site_file_content`.

### 5. Плейбук для роли, версионирование и сборка архива

1. Создан плейбук `site.yml`, использующий роль `my_own_namespace.yandex_cloud_elk.site_file`.
2. Заполнены метаданные `galaxy.yml` и документация `README.md` коллекции.
3. Изменения закоммичены в репозиторий `my_own_collection`, проставлен git-тег `1.0.0`.
4. Выполнена сборка архива коллекции:
   * Команда сборки: `ansible-galaxy collection build`
   * Собран артефакт: `my_own_namespace-yandex_cloud_elk-1.0.0.tar.gz`

### 6. Тестирование установки коллекции и запуска роли

1. Создана изолированная тестовая директория, куда скопированы плейбук `site.yml` и архив `my_own_namespace-yandex_cloud_elk-1.0.0.tar.gz`.
2. Коллекция установлена из локального архива:

<img width="1020" height="100" alt="Снимок экрана 2026-09-13 133549" src="https://github.com/user-attachments/assets/cc006f46-2a46-45ae-a2f0-38ef08728ee7" />

3. Запущен плейбук `site.yml`, подтвердивший успешное создание файла через установленную коллекцию:

<img width="876" height="256" alt="Снимок экрана 2026-09-13 133746" src="https://github.com/user-attachments/assets/c2c5e513-9678-46be-9625-b622c4bb7a82" />

---

### Ссылки на материалы

* **Репозиторий коллекции**: https://github.com/Yacuba/my_own_collection
* **Архив коллекции (.tar.gz)**: [my_own_namespace-yandex_cloud_elk-1.0.0.tar.gz](https://github.com/Yacuba/my_own_collection/releases/download/1.0.0/my_own_namespace-yandex_cloud_elk-1.0.0.tar.gz)

---

## Необязательная часть

### 1. Реализация модуля управления ВМ в Yandex Cloud (`yc_instance`)

Разработан собственный Ansible-модуль `yc_instance.py` (размещен в `plugins/modules/yc_instance.py` коллекции):
* **Зависимости**: использует CLI-утилиту `yc` для выполнения операций в облаке.
* **Функционал**: позволяет декларативно управлять виртуальными машинами в Yandex Cloud, настраивать сайзинг (vCPU, RAM, core-fraction, размер диска), образ ОС (`almalinux-9`), зону доступности, подсеть и SSH-ключи.
* **Идемпотентность**: перед любыми действиями модуль опрашивает API облака через `yc compute instance get`. Если инстанс уже существует в целевом состоянии, повторное создание не выполняется (`changed=False`).
* **Check mode**: полностью поддерживает режим симуляции.

Тестирование модуля на создание, идемпотентность и удаление:

<img width="1131" height="690" alt="Снимок экрана 2026-09-13 141527" src="https://github.com/user-attachments/assets/747c2050-1420-43e9-ace2-ffe14472e043" />

---

### 2. Включение ролей в состав коллекции

В коллекцию `my_own_namespace.yandex_cloud_elk` (версия `1.1.0`) добавлены собственные роли из предыдущих заданий:
* `roles/vector` — развертывание и конфигурирование агента сбора логов Vector;
* `roles/lighthouse` — настройка веб-интерфейса LightHouse и конфигурация виртуального хоста Nginx.

*Примечание к ClickHouse:* для СУБД ClickHouse в комплексном сценарии использован чистый, оптимизированный под AlmaLinux 9 блок установки RPM-дистрибутива с сетевым доступом на порт `8123`.

---

### 3. Комплексный плейбук развертывания Observability-стека

Разработан плейбук `deploy_observability.yml` (включен в каталог `playbooks/` коллекции):
1. **Провижининг инфраструктуры**: модуль `yc_instance` в цикле создает виртуальные машины `clickhouse-01`, `vector-01`, `lighthouse-01` в Yandex Cloud.
2. **Динамический inventory**: полученные внешние IP-адреса хостов автоматически регистрируются в инвентаре с помощью `ansible.builtin.add_host`.
3. **Ожидание готовности**: модуль `wait_for` проверяет доступность порта 22 на созданных серверах.
4. **Настройка ClickHouse**: устанавливаются пакеты ClickHouse, сервис переводится в режим прослушивания внешних интерфейсов (`<listen_host>0.0.0.0</listen_host>`), создается база данных `logs`.
5. **Деплой Vector**: применяется роль `my_own_namespace.yandex_cloud_elk.vector`.
6. **Деплой LightHouse**: применяется роль `my_own_namespace.yandex_cloud_elk.lighthouse` поверх веб-сервера Nginx.

Результат сквозного развертывания стека в Yandex Cloud (PLAY RECAP):

<img width="824" height="106" alt="Снимок экрана 2026-09-13 154727" src="https://github.com/user-attachments/assets/17e8eb2a-e17f-4a9c-b163-b108ebec6d76" />

Проверка доступности и интеграции веб-интерфейса LightHouse с СУБД ClickHouse по внешнему IP:

<img width="1214" height="548" alt="Снимок экрана 2026-09-13 154823" src="https://github.com/user-attachments/assets/be514018-8f17-4151-aba1-a2fc2c23db48" />

---

### Ссылки на релиз коллекции 1.1.0

* **Репозиторий коллекции**: https://github.com/Yacuba/my_own_collection
* **Релиз коллекции 1.1.0 с модулем `yc_instance` и ролями**: https://github.com/Yacuba/my_own_collection/releases/tag/1.1.0
* **Архив коллекции 1.1.0 (.tar.gz)**: [my_own_namespace-yandex_cloud_elk-1.1.0.tar.gz](https://github.com/Yacuba/my_own_collection/releases/download/1.1.0/my_own_namespace-yandex_cloud_elk-1.1.0.tar.gz)
