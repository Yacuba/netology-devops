# Домашнее задание к занятию 5 «Тестирование roles»

## Подготовка к выполнению

### 1. Настройка изолированного окружения и установка Molecule
Для изоляции зависимостей от системного интерпретатора Python было создано отдельное виртуальное окружение:

```bash
python3 -m venv ~/.venvs/molecule-venv
source ~/.venvs/molecule-venv/bin/activate
pip install --upgrade pip
pip install "molecule" "molecule-plugins[docker,podman]"
```

### 2. Загрузка вспомогательного образа для Tox
Был загружен образ `aragast/netology:latest`, содержащий предустановленные интерпретаторы Python (3.7, 3.9), утилиту Tox и Podman:

```bash
docker pull aragast/netology:latest
```

### 3. Проверка установленных компонентов
Проверена доступность драйверов Molecule и наличие загруженного Docker-образа:

```bash
molecule --version && docker images | grep aragast
```

<img width="983" height="222" alt="Снимок экрана 2026-09-08 145212" src="https://github.com/user-attachments/assets/256e4fcf-9743-4620-a52f-0b29b2b4836f" />

---

## Основная часть

### Molecule

#### 1. Исследование сценариев тестирования роли ClickHouse
В качестве примера использования Molecule в реальных проектах была исследована структура сценариев роли ClickHouse (`AlexeySetevoi/ansible-clickhouse`), загруженной на предыдущем этапе.

Была предпринята попытка запуска сценариев тестирования:
```bash
molecule test -s ubuntu_xenial; \
molecule test -s centos_7
```

Команды завершились ошибкой валидации манифестов `molecule.yml`:
```text
ERROR Failed to validate .../roles/clickhouse/molecule/ubuntu_xenial/molecule.yml
ERROR Failed to validate .../roles/clickhouse/molecule/centos_7/molecule.yml
```

Причиной ошибки является несовместимость устаревшей схемы Molecule 2/3 со строгой валидацией актуальной версии Molecule 26.x. Подобное поведение является штатным и демонстрирует эволюцию формата конфигураций Molecule.

<img width="1093" height="115" alt="Снимок экрана 2026-09-08 151204" src="https://github.com/user-attachments/assets/21620abf-6ff9-40bd-b6ed-979237db43c5" />

#### 2. Инициализация сценария Molecule для vector-role
В каталог `08-ansible-05-testing/roles/` был склонирован рабочий репозиторий роли [vector-role](https://github.com/Yacuba/vector-role):

```bash
git clone git@github.com:Yacuba/vector-role.git
```

При попытке запуска команды `molecule init scenario --driver-name docker` утилита вернула ошибку `Error: No such option '--driver-name'`. В версиях Molecule 5+ ключ `--driver-name` был удален из интерфейса командной строки инициализации. Назначение драйвера и платформ теперь осуществляется непосредственно через файл конфигурации `molecule.yml`.

Инициализация базового сценария по умолчанию выполнена командой:
```bash
molecule init scenario
```

<img width="1164" height="680" alt="Снимок экрана 2026-09-08 152807" src="https://github.com/user-attachments/assets/4b4f458d-48b8-412c-97fe-9ed1721cf469" />

#### 3. Настройка мультиплатформенного тестирования и устранение ошибок
В конфигурационный файл `molecule/default/molecule.yml` были добавлены две платформы: `oraclelinux:8` и `ubuntu:latest`:

```yaml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: oraclelinux8
    image: docker.io/library/oraclelinux:8
    privileged: true
    cgroupns_mode: host
    command: /usr/sbin/init
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
  - name: ubuntu
    image: docker.io/library/ubuntu:latest
    privileged: true
    cgroupns_mode: host
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
provisioner:
  name: ansible
verifier:
  name: ansible
scenario:
  test_sequence:
    - destroy
    - syntax
    - create
    - converge
    - idempotence
    - verify
    - destroy
```

Были устранены сгенерированные файлы-заглушки `create.yml` и `destroy.yml`, чтобы Molecule делегировал управление контейнерами встроенному модулю `molecule-plugins`.

Первичное создание и тестирование:
1. Утилита `ansible-compat` отклонила имя `Yacuba.vector` из-за использования заглавной буквы в авторе. В `meta/main.yml` было явно задано пространство имен `namespace: yacuba` и имя `vector` в нижнем регистре, а в `molecule/default/converge.yml` прописан вызов по FQRN (`yacuba.vector`).
2. Контейнеры были успешно развернуты драйвером Docker.

<img width="1016" height="302" alt="Снимок экрана 2026-09-09 183718" src="https://github.com/user-attachments/assets/f3459f43-8c5e-4e50-b32c-8dab766ffe8e" />

3. В стандартном Docker-образе `ubuntu:latest` отсутствует работающий демон `systemd`. Модуль `ansible.builtin.service` пытался найти SysVinit-скрипт `/etc/init.d/vector`, завершаясь ошибкой `Could not find the requested service vector: `. В то же время на `oraclelinux8` служба запустилась успешно благодаря запуску контейнера с `/usr/sbin/init`.

<img width="838" height="347" alt="Снимок экрана 2026-09-09 185444" src="https://github.com/user-attachments/assets/2e0ca647-c23e-4210-9f06-373b488da04e" />

Для обеспечения совместимости как с полноценными виртуальными машинами, так и с изолированными контейнерами без init-системы, в таску запуска службы (`tasks/main.yml`) и хендлер (`handlers/main.yml`) было добавлено условие:
```yaml
when: ansible_service_mgr == 'systemd'
```

Повторный запуск команды `molecule converge` подтвердил успешное применение роли на обеих платформах и нулевое количество изменений при повторном прогоне (идемпотентность).

<img width="860" height="159" alt="Снимок экрана 2026-09-09 190116" src="https://github.com/user-attachments/assets/dd3bd2fe-c2c9-459a-ae99-090281094ea9" />

#### 4. Разработка проверок работоспособности (verify.yml)
В файл `molecule/default/verify.yml` были включены комплексные проверки состояния развернутого сервиса:
* Наличие и исполняемость бинарного файла `/usr/bin/vector`.
* Корректность вызова и кода возврата команды `vector --version`.
* Наличие сгенерированного файла конфигурации `/etc/vector/vector.yaml`.
* **Валидация конфигурации** средствами самого приложения (`vector validate --config-yaml /etc/vector/vector.yaml`).
* Проверка активного статуса службы (`state: running`) через модуль `service_facts` для платформ с подсистемой `systemd`.

```bash
molecule verify
```

Все проверки завершились успешно (`failed=0`):

<img width="854" height="233" alt="Снимок экрана 2026-09-09 191246" src="https://github.com/user-attachments/assets/5b0aa60f-6299-41ea-8bb1-539192d2e5db" />

#### 5. Полное тестирование жизненного цикла роли (molecule test)
Был выполнен сквозной прогон сценария тестирования роли на чистых контейнерах:
```bash
molecule test
```

В рамках сценария успешно отработали все фазы матрицы тестирования: `destroy` -> `syntax` -> `create` -> `converge` -> `idempotence` -> `verify` -> `destroy`.

<img width="690" height="208" alt="Снимок экрана 2026-09-09 192758" src="https://github.com/user-attachments/assets/c48d8dc2-9033-4bfa-ba95-a6ce82a48f11" />

#### 6. Семантическое версионирование и публикация релиза
Все изменения были зафиксированы в Git. Был создан тег **`1.1.0`** и отправлен в удаленный репозиторий [vector-role](https://github.com/Yacuba/vector-role):

### Tox

#### 1. Подготовка конфигурационных файлов Tox
В корень репозитория роли `vector-role` были добавлены конфигурационные файлы:
* `tox.ini` — описание матрицы тестирования для сред Python 3.7 и 3.9 с версиями Ansible 2.10 и 3.0.
* `tox-requirements.txt` — список зависимостей Python (Molecule, драйвер `molecule_podman`, selinux и сопутствующие библиотеки).

#### 2. Запуск контейнера со специальным сборочным окружением
Для тестирования в изолированной среде был запущен специализированный контейнер `aragast/netology:latest` в привилегированном режиме с монтированием каталога роли:

```bash
docker run --privileged=True -v "$(pwd)":/opt/vector-role -w /opt/vector-role -it aragast/netology:latest /bin/bash
```

#### 3. Первичный запуск Tox
Внутри контейнера была выполнена команда запуска матрицы тестирования:
```bash
tox
```

Команда завершилась ожидаемой ошибкой отсутствия сценария тестирования:
```text
CRITICAL 'molecule/compatibility/molecule.yml' glob failed. Exiting.
ERROR: InvocationError for command ... molecule test -s compatibility --destroy always
```

<img width="1020" height="121" alt="Снимок экрана 2026-09-09 195450" src="https://github.com/user-attachments/assets/bbd93904-c1cb-4788-9705-b67227f56dde" />

#### 4. Создание облегченного сценария Molecule с драйвером Podman
Для быстрой проверки роли в изолированных средах тестирования Tox был разработан легковесный сценарий `molecule/compatibility`:
* **Драйвер**: `podman` (плагин `molecule_podman`).
* **Платформа**: оптимизированный образ `docker.io/pycontribs/centos:8` с предустановленным интерпретатором Python 3.6.
* **Матрица тестов**: сокращена до базовых шагов `destroy` -> `create` -> `converge` -> `verify` -> `destroy` без избыточных задержек.

Проверка сценария на исполнимость в окружении `py37-ansible210`:
```bash
molecule test -s compatibility
```
Сценарий отработал штатно, верификация подтвердила успешную установку и валидность Vector.

<img width="818" height="130" alt="Снимок экрана 2026-09-10 111046" src="https://github.com/user-attachments/assets/fab2fce9-f5e2-47cf-a6e0-cc30caa08743" />

#### 5. Настройка tox.ini и зависимостей
В файле `tox.ini` была настроена команда запуска облегченного сценария:
```ini
commands =
    {posargs:molecule test -s compatibility --destroy always}
```

В ходе отладки матричного тестирования была выявлена несовместимость версий в окружении Python 3.9: утилита `ansible-compat >= 4` отвергала `ansible < 3.0` с ошибкой минимальной поддерживаемой версии. Для обеспечения воспроизводимости и стабильности всех сред в `tox-requirements.txt` были жестко зафиксированы версии компонентов:

```text
selinux
lxml
molecule==3.6.1
molecule_podman==1.1.0
ansible-compat<2.0.0
jmespath
```

#### 6. Итоговый запуск Tox
Внутри контейнера была запущена полная матрица тестирования с пересозданием виртуальных окружений:
```bash
tox -r
```

Все 4 тестовые среды (`py37-ansible210`, `py37-ansible30`, `py39-ansible210`, `py39-ansible30`) успешно прошли тестирование:

<img width="276" height="94" alt="Снимок экрана 2026-09-10 112520" src="https://github.com/user-attachments/assets/7e989c7a-a1fd-45b8-9290-fb6e7e26e57c" />

#### 7. Семантическое версионирование (Tox)
Все артефакты (сценарий `molecule/compatibility`, файлы `tox.ini`, `tox-requirements.txt`) были зафиксированы в репозитории [vector-role](https://github.com/Yacuba/vector-role). Был присвоен и опубликован тег **`1.2.0`**.

---

## Итоги выполнения

* **Репозиторий роли**: [https://github.com/Yacuba/vector-role](https://github.com/Yacuba/vector-role)
* **Тег решения Molecule**: [`1.1.0`](https://github.com/Yacuba/vector-role/releases/tag/1.1.0)
* **Тег решения Tox**: [`1.2.0`](https://github.com/Yacuba/vector-role/releases/tag/1.2.0)
* В репозитории роли присутствуют два сценария Molecule - `default` на базе Docker и `compatibility` на базе Podman, а также файлы `tox.ini` и `tox-requirements.txt`.

---

## Необязательная часть

### 1. Настройка тестирования роли LightHouse с помощью Molecule
В каталог `roles/lighthouse-role` был склонирован репозиторий [lighthouse-role](https://github.com/Yacuba/lighthouse-role). 

Для роли был разработан сценарий тестирования Molecule:
1. **Подготовительный этап (`prepare.yml`)**: установка веб-сервера Nginx, пакетов `git`, `curl` и деплой чистого базового конфигурационного файла `nginx.conf`.
2. **Адаптация роли под контейнеры**: таска применения контекста SELinux снабжена условием проверки доступности подсистемы (`ansible_facts.selinux.status == 'enabled'`), а в таску скачивания дистрибутива с GitHub добавлен механизм повторных попыток (`retries: 5`, `delay: 3`) для исключения сбоев сетевого рукопожатия SSL.
3. **Проверки (`verify.yml`)**: выполнена проверка наличия статики, валидация синтаксиса `nginx -t`, а также проверка реального HTTP-ответа (`200 OK`) и содержимого веб-страницы LightHouse.

```bash
molecule test
```

Тестирование роли завершилось со 100% успехом:

<img width="687" height="223" alt="Снимок экрана 2026-09-10 125029" src="https://github.com/user-attachments/assets/6e011b94-1596-4eb4-be10-e017cd947dd3" />

Изменения зафиксированы в репозитории [lighthouse-role](https://github.com/Yacuba/lighthouse-role) с тегом **`1.1.0`**.

### 2. Сценарий сквозного тестирования полного стека (stack)
Внутри роли `vector-role` был разработан интеграционный сценарий `molecule/stack`, поднимающий весь рабочий стек компонентов в изолированной Docker-сети `stack-net`:
* **`clickhouse-node`**: узел СУБД ClickHouse, настроенный на прослушивание IPv4 (`0.0.0.0`).
* **`vector-node`**: узел агента Vector, осуществляющий сбор и передачу логов.
* **`lighthouse-node`**: веб-интерфейс LightHouse на веб-сервере Nginx.

#### Автономность и внешние зависимости (requirements.yml)
Для переносимости сценария зависимости зафиксированы в `molecule/stack/requirements.yml` с использованием публичных HTTPS-репозиториев:
```yaml
---
- src: https://github.com/AlexeySetevoi/ansible-clickhouse.git
  scm: git
  version: "1.13"
  name: clickhouse

- src: https://github.com/Yacuba/lighthouse-role.git
  scm: git
  version: "1.1.0"
  name: lighthouse-role
```
На этапе `dependency` утилита Molecule автоматически выкачивает роли через Ansible Galaxy в изолированный кэш окружения.

### 3. Проверка интеграции стека (verify.yml)
В файле `molecule/stack/verify.yml` реализованы проверки межсервисного взаимодействия:
1. **ClickHouse Health**: проверка локального HTTP эндпоинта `/ping` и подтверждение создания базы данных `logs`.
2. **Vector Pipeline**: валидация синтаксиса конфигурации (`vector validate`) и проверка сетевой доступности порта приёма данных СУБД (`http://clickhouse-node:8123/ping`) с узла сбора логов.
3. **LightHouse Frontend & API Integration**: локальная доступность веб-интерфейса (порт 80) и **выполнение запроса к ClickHouse API с узла LightHouse** (`http://clickhouse-node:8123/?query=SHOW%20DATABASES`), подтверждающее способность GUI опрашивать базу данных в распределенной сети.

Запуск полного цикла тестирования стека:
```bash
molecule test -s stack
```

Все фазы (`dependency` -> `create` -> `prepare` -> `converge` -> `idempotence` -> `verify` -> `destroy`) завершились со 100% успехом:

<img width="894" height="237" alt="Снимок экрана 2026-09-12 121944" src="https://github.com/user-attachments/assets/71790107-18b7-4c64-9a34-e168e0fcc026" />

### 4. Публикация ролей и версионирование

Все роли опубликованы в публичных репозиториях GitHub с соответствующими версиями:

* **Vector Role**: [https://github.com/Yacuba/vector-role](https://github.com/Yacuba/vector-role)
  * Тег Molecule Docker сценария: [`1.1.0`](https://github.com/Yacuba/vector-role/releases/tag/1.1.0)
  * Тег Tox + Podman сценария: [`1.2.0`](https://github.com/Yacuba/vector-role/releases/tag/1.2.0)
  * Тег Full-Stack сценария: [`1.3.0`](https://github.com/Yacuba/vector-role/releases/tag/1.3.0)
* **LightHouse Role**: [https://github.com/Yacuba/lighthouse-role](https://github.com/Yacuba/lighthouse-role)
  * Тег Molecule Nginx сценария: [`1.1.0`](https://github.com/Yacuba/lighthouse-role/releases/tag/1.1.0)
