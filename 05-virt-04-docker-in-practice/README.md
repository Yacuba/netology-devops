# Домашнее задание к занятию 5. «Практическое применение Docker»

## Задача 0. Проверка окружения Docker

1. Проверка отсутствия старой утилиты `docker-compose`:
```bash
docker-compose --version
```

2. Проверка версии плагина `docker compose`:
```bash
docker compose version
```

<img width="572" height="117" alt="Снимок экрана 2026-07-23 163055" src="https://github.com/user-attachments/assets/09a5dcc1-f341-4f57-b928-e8dac2d2aab4" />

---

## Задача 1. Разработка Dockerfile и сборка образа

1. Выполнен `fork` репозитория `shvirtd-example-python` и его клонирование:
```bash
git clone https://github.com/Yacuba/shvirtd-example-python.git
cd shvirtd-example-python
```

2. Создан файл `.dockerignore`:
```text
.git
.gitignore
__pycache__
*.pyc
*.pyo
*.pyd
.venv
venv
ENV
.env
Dockerfile*
compose*.yaml
README.md
```

3. Разработан файл `Dockerfile.python` с применением multistage-сборки на базе образа `python:3.12-slim`:

<img width="632" height="358" alt="Снимок экрана 2026-07-23 165656" src="https://github.com/user-attachments/assets/1ca0636a-de1d-40ea-ac52-42cbe6dd201a" />

4. Выполнена команда сборки Docker-образа:
```bash
docker build -f Dockerfile.python -t test-python-app:v1 .
```

<img width="1097" height="612" alt="Снимок экрана 2026-07-23 165715" src="https://github.com/user-attachments/assets/06ba30be-fe3c-4983-8200-15e5a1377d93" />

---

### Дополнительное задание 1.3 (*) - Запуск приложения без Docker (через venv)

1. Запуск контейнера MySQL 8 с учетными данными проекта:
```bash
docker run -d --name mysql-local \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=very_strong \
  -e MYSQL_DATABASE=example \
  -e MYSQL_USER=app \
  -e MYSQL_PASSWORD=very_strong \
  mysql:8
```

2. Установка системных зависимостей, создание виртуального окружения и установка пакетов Python:
```bash
sudo apt-get update && sudo apt-get install -y python3.12-venv python3-pip
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

3. Экспорт переменных окружения и запуск приложения:
```bash
export DB_HOST='127.0.0.1'
export DB_USER='app'
export DB_PASSWORD='very_strong'
export DB_NAME='example'

uvicorn main:app --host 0.0.0.0 --port 5000
```

4. Отправка тестового запроса с помощью `curl`:
```bash
curl http://127.0.0.1:5000
```

<img width="1096" height="79" alt="Снимок экрана 2026-07-23 170959" src="https://github.com/user-attachments/assets/0c1d2b60-2850-4466-b36c-00e945f27410" />

---

### Дополнительное задание 1.4 (*) - Управление названием таблицы через ENV-переменную

1. В файл `main.py` добавлено считывание переменной окружения `DB_TABLE`:
```python
db_table = os.environ.get('DB_TABLE', 'requests')
```

2. В SQL-запросы (`CREATE TABLE`, `INSERT INTO`, `SELECT FROM`) подставлена переменная `db_table` вместо жестко заданной строки `"requests"`.

3. Проверка работы приложения с переменной `DB_TABLE='custom_table'`:
```bash
export DB_TABLE='custom_table'
uvicorn main:app --host 0.0.0.0 --port 5000
```

4. Отправка тестового HTTP-запроса:
```bash
curl http://127.0.0.1:5000
```

5. Проверка создания таблицы `custom_table` в MySQL:
```bash
docker exec -ti mysql-local mysql -uapp -pvery_strong -e "use example; show tables;"
```

<img width="925" height="154" alt="Снимок экрана 2026-07-23 173530" src="https://github.com/user-attachments/assets/5561ea04-eb8e-4fc1-8aee-bee9eb412964" />

## Задача 2 (*)

1. Создан Yandex Container Registry с именем `test`:
```bash
yc container registry create --name test
```
ID созданного реестра: `crpvhk8tgssq2h3392rm`.

2. Настроена аутентификация локального Docker:
```bash
yc container registry configure-docker
```

3. Образ `test-python-app:v1` затегирован и загружен в Yandex Container Registry:
```bash
docker tag test-python-app:v1 cr.yandex/crpvhk8tgssq2h3392rm/test-python-app:v1
docker push cr.yandex/crpvhk8tgssq2h3392rm/test-python-app:v1
```

4. Выполнено сканирование образа на уязвимости:
```bash
yc container image scan crpnj2lq58gmfrk38e96
yc container image list-vulnerabilities --scan-result-id cheh7ofcrpgpjprohc0r
```

5. Отчет сканирования:
Обнаружено 169 уязвимостей (4 Critical, 19 High, 54 Medium, 63 Low, 29 Undefined).

<img width="1106" height="535" alt="Снимок экрана 2026-07-24 204306" src="https://github.com/user-attachments/assets/b6798cd3-ac30-4dc3-8ae2-96e87f76507d" />
<img width="892" height="463" alt="Снимок экрана 2026-07-24 204335" src="https://github.com/user-attachments/assets/8690aadb-8916-4fcb-abeb-873485ceb91b" />

## Задача 3. Разработка compose.yaml и запуск стека сервисов

1. В корне проекта создан файл `compose.yaml`, подключающий `proxy.yaml` через директиву `include`. В файле описаны сервисы `db` (MySQL 8) и `web` (FastAPI-приложение на базе образа из Yandex Container Registry), а также настроена сеть `backend` с фиксированными IP-адресами:

```yaml
include:
  - proxy.yaml

services:
  db:
    image: mysql:8
    container_name: db
    restart: always
    env_file:
      - .env
    networks:
      backend:
        ipv4_address: 172.20.0.10

  web:
    image: cr.yandex/crpvhk8tgssq2h3392rm/test-python-app:v1
    container_name: web
    restart: always
    env_file:
      - .env
    environment:
      DB_HOST: db
      DB_USER: app
      DB_PASSWORD: QwErTy1234
      DB_NAME: virtd
    depends_on:
      - db
    networks:
      backend:
        ipv4_address: 172.20.0.5

networks:
  backend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
```

2. Запуск сервисов в фоновом режиме:
```bash
docker compose up -d
```

3. Выполнена проверка работы сервиса через запрос на порт 8090 (ingress-proxy):
```bash
curl -L http://127.0.0.1:8090 -w "\n"
```

4. Выполнено подключение к СУБД MySQL и проверка содержимого таблицы `requests`:
```bash
docker exec -ti db mysql -uroot -pYtReWq4321 -e "show databases; use virtd; show tables; SELECT * from requests LIMIT 10;"
```

<img width="815" height="457" alt="Снимок экрана 2026-07-24 212201" src="https://github.com/user-attachments/assets/533e513d-c5ca-4c76-a75e-503bd37f5fd6" />
