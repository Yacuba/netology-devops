# Домашнее задание к занятию 6 «Оркестрация кластером Docker контейнеров на примере Docker Swarm»

## Задача 1. Создание Docker Swarm-кластера в Yandex Cloud

В рамках выполнения задачи в облаке Yandex Cloud были созданы 3 виртуальные машины в одной подсети:
* `manager-01` — Управляющая нода (Manager)
* `worker-01` — Рабочая нода (Worker)
* `worker-02` — Рабочая нода (Worker)

---

1. Проверка окружения и подсети Yandex Cloud

С помощью CLI `yc` была проверена конфигурация и доступность сети/подсети:

```bash
yc vpc network list
yc vpc subnet list
```

<img width="1109" height="405" alt="Снимок экрана 2026-07-30 163626" src="https://github.com/user-attachments/assets/7aea93db-551e-4caa-8fb6-8d210e548a87" />

---

2. Создание 3 виртуальных машин через CLI `yc`

ВМ были созданы на базе **Ubuntu 22.04 LTS**:

```bash
# manager-01
yc compute instance create \
  --name manager-01 \
  --zone ru-central1-a \
  --network-interface subnet-id=e9bdnl5q91m9u4dqmf4c,nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=20,type=network-hdd \
  --cores 2 --core-fraction 20 --memory 2 \
  --preemptible \
  --metadata ssh-keys="ubuntu:$(cat ~/.ssh/id_rsa.pub)"

# worker-01
yc compute instance create \
  --name worker-01 \
  --zone ru-central1-a \
  --network-interface subnet-id=e9bdnl5q91m9u4dqmf4c,nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=20,type=network-hdd \
  --cores 2 --core-fraction 20 --memory 2 \
  --preemptible \
  --metadata ssh-keys="ubuntu:$(cat ~/.ssh/id_rsa.pub)"

# worker-02
yc compute instance create \
  --name worker-02 \
  --zone ru-central1-a \
  --network-interface subnet-id=e9bdnl5q91m9u4dqmf4c,nat-ip-version=ipv4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=20,type=network-hdd \
  --cores 2 --core-fraction 20 --memory 2 \
  --preemptible \
  --metadata ssh-keys="ubuntu:$(cat ~/.ssh/id_rsa.pub)"
```

Проверка созданных виртуальных машин:
```bash
yc compute instance list
```

<img width="866" height="163" alt="Снимок экрана 2026-07-30 171442" src="https://github.com/user-attachments/assets/a13d5d00-13a2-4e03-9b12-e8bb83ff9886" />

---

3. Установка Docker на каждую ВМ

На все три виртуальные машины был установлен Docker Engine с помощью официального скрипта установки `get.docker.com`:

```bash
NODES=("158.160.111.137" "89.169.136.99" "111.88.244.157")

for ip in "${NODES[@]}"; do
  ssh -o StrictHostKeyChecking=no ubuntu@$ip "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo usermod -aG docker ubuntu"
done
```

Проверка версии Docker на нодах:
```bash
for ip in "${NODES[@]}"; do
  ssh -o StrictHostKeyChecking=no ubuntu@$ip "docker --version"
done
```

<img width="599" height="197" alt="Снимок экрана 2026-07-30 172530" src="https://github.com/user-attachments/assets/610a8f07-9169-4cc0-a483-5b62515f904e" />

---

4. Инициализация и сборка Docker Swarm кластера

1. На ноде `manager-01` инициализирован Swarm-кластер на внутреннем IP-адресе:
   ```bash
   ssh ubuntu@158.160.111.137 "docker swarm init --advertise-addr 10.128.0.11"
   ```

2. Получен токен для присоединения воркеров:
   ```bash
   SWARM_TOKEN=$(ssh ubuntu@158.160.111.137 "docker swarm join-token worker -q")
   ```

3. Воркер-ноды подключены к кластеру:
   ```bash
   ssh ubuntu@89.169.136.99 "docker swarm join --token $SWARM_TOKEN 10.128.0.11:2377"
   ssh ubuntu@111.88.244.157 "docker swarm join --token $SWARM_TOKEN 10.128.0.11:2377"
   ```

4. Проверка состояния узлов кластера с помощью `docker node ls` на `manager-01`:
   ```bash
   ssh ubuntu@158.160.111.137 "docker node ls"
   ```

<img width="992" height="97" alt="Снимок экрана 2026-07-30 172823" src="https://github.com/user-attachments/assets/2e8faf2f-7f2e-44fe-9ebd-341b77741a1e" />

## Задача 2 (*). Развертывание приложения в Docker Swarm кластере

Для проведения деплоя в чистом распределенном окружении кластер виртуальных машин в Yandex Cloud был развернут заново с нуля, после чего на управляющей ноде `manager-01` был повторно клонирован форк репозитория `shvirtd-example-python`.

### 1. Состояние заново развернутого кластера

Проверка созданных виртуальных машин и состояния Swarm-нод:

```bash
yc compute instance list
ssh ubuntu@111.88.243.226 "docker node ls"
```

<img width="996" height="270" alt="Снимок экрана 2026-08-02 181516" src="https://github.com/user-attachments/assets/947d8d26-291f-4c40-88d0-8ab0eb6807b6" />

Клонирование форка репозитория на ноде `manager-01`:
```bash
git clone https://github.com/Yacuba/shvirtd-example-python.git && cd shvirtd-example-python
```

<img width="678" height="554" alt="Снимок экрана 2026-08-02 181651" src="https://github.com/user-attachments/assets/2cfed080-7687-4c09-92e0-2f90d7b5bc45" />

---

### 2. Подготовка Yandex Container Registry и пуш образа

Для того чтобы воркер-ноды (`worker-01`, `worker-02`) могли беспрепятственно выкачивать собранный образ приложения без использования локальных файлов ноды-менеджера, в Yandex Cloud был создан приватный Container Registry.

1. **Создание реестра в Yandex Cloud:**
   ```bash
   yc container registry create --name swarm-registry
   ```
   *Создан реестр с ID: `crp6dimelnipu5rbocfp`.*

   <img width="691" height="234" alt="Снимок экрана 2026-08-02 181802" src="https://github.com/user-attachments/assets/b65f375d-8687-4d56-97b5-861bc6cf605b" />

2. **Авторизация Docker в YCR на `manager-01`:**
   Авторизация выполнена путем передачи IAM-токена по SSH:
   ```bash
   echo $(yc iam create-token) | ssh ubuntu@111.88.243.226 "docker login --username iam --password-stdin cr.yandex"
   ```

3. **Сборка и пуш образа Python-приложения:**
   Сборка образа выполнена с отключением OCI-аттестаций (`--provenance=false`), так как реестр YCR строго ожидает манифесты формата *Docker Schema 2*:
   ```bash
   # Сборка образа
   docker buildx build --provenance=false -t cr.yandex/crp6dimelnipu5rbocfp/web:v1 -f Dockerfile.python . --load

   # Пуш образа в YCR
   docker push cr.yandex/crp6dimelnipu5rbocfp/web:v1
   ```

---

### 3. Адаптация конфигурационных файлов под Docker Swarm

Для обеспечения работы приложения в распределенном Swarm-кластере были внесены следующие изменения в конфигурационные файлы:

#### 1. Адаптация HAProxy (`./haproxy/reverse/haproxy.cfg`)
- Заменен статический IP-адрес `172.20.0.5` на имя сервиса `web`.
- Добавлена секция `resolvers docker` со встроенным DNS Swarm (`127.0.0.11:53`) для динамического резолвинга IP-адресов контейнеров в сети `overlay`.

Файл `./haproxy/reverse/haproxy.cfg`:
```haproxy
global
  maxconn 1000

defaults
  default-server init-addr none

resolvers docker
  nameserver dns1 127.0.0.11:53

frontend http_front
  bind *:8080
  mode http
  default_backend http_back

backend http_back
  balance roundrobin
  mode http
  server web web:5000 check resolvers docker
```

#### 2. Адаптация Nginx (`./nginx/ingress/default.conf`)
- Адрес перенаправления `127.0.0.1:8080` (из `network_mode: host`) заменен на сетевое имя сервиса HAProxy — `http://reverse-proxy:8080`.

Файл `./nginx/ingress/default.conf`:
```nginx
server {
    listen 8090;
    server_name _;

    location / {
        proxy_pass http://reverse-proxy:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

#### 3. Создание распределенного манифеста Swarm (`docker-stack.yml`)
Вместо Compose-файлов подготовлен стек `docker-stack.yml`:
- конфигурации Nginx и HAProxy доставляются на воркер-ноды через встроенный механизм `Swarm Configs`.
- использован драйвер `overlay` для связи контейнеров на разных физических хостах.
- сервис `web` масштабирован до 3 реплик (по 1 на каждую ВМ кластера).

Файл `docker-stack.yml`:
```yaml
version: '3.8'

services:
  db:
    image: mysql:8
    command: --mysql-native-password=ON
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    networks:
      - backend
    deploy:
      placement:
        constraints:
          - node.role == manager

  web:
    image: cr.yandex/crp6dimelnipu5rbocfp/web:v1
    environment:
      DB_HOST: db
      DB_USER: ${MYSQL_USER}
      DB_PASSWORD: ${MYSQL_PASSWORD}
      DB_NAME: ${MYSQL_DATABASE}
    networks:
      - backend
    deploy:
      replicas: 3

  reverse-proxy:
    image: haproxy:2.4
    configs:
      - source: haproxy_config
        target: /usr/local/etc/haproxy/haproxy.cfg
    ports:
      - "8080:8080"
    networks:
      - backend
    deploy:
      replicas: 2

  ingress-proxy:
    image: nginx:latest
    configs:
      - source: nginx_ingress_conf
        target: /etc/nginx/conf.d/default.conf
      - source: nginx_conf
        target: /etc/nginx/nginx.conf
    ports:
      - "8090:8090"
    networks:
      - backend
    deploy:
      replicas: 2

configs:
  haproxy_config:
    file: ./haproxy/reverse/haproxy.cfg
  nginx_ingress_conf:
    file: ./nginx/ingress/default.conf
  nginx_conf:
    file: ./nginx/ingress/nginx.conf

networks:
  backend:
    driver: overlay
```

---

### 4. Запуск стека и проверка распределенной работы

1. **Экспорт переменных и запуск стека:**
   Флаг `--with-registry-auth` передан для авто-авторизации воркер-нод в YCR:
   ```bash
   export $(grep -v '^#' .env | tr -d '"' | xargs) && docker stack deploy --with-registry-auth -c docker-stack.yml python_stack
   ```

2. **Проверка состояния сервисов и распределения реплик:**
   ```bash
   docker stack services python_stack
   docker service ps python_stack_web
   ```
   *Вывод подтверждает, что 3 реплики `web` успешно запущены на трех разных узлах (`manager-01`, `worker-01`, `worker-02`).*

   <img width="1288" height="272" alt="Снимок экрана 2026-08-02 183437" src="https://github.com/user-attachments/assets/e1a24a34-c543-457c-8f36-21c3543f8e7a" />

3. **Проверка доступности приложения из внешней сети:**
   Выполнен внешний HTTP-запрос `curl` на порт `8090`:
   ```bash
   curl http://111.88.243.226:8090 -w "\n"
   ```
   *Ответ: `"TIME: 2026-08-02 15:36:53, IP: 10.0.0.2"`.*

   <img width="579" height="43" alt="Снимок экрана 2026-08-02 183704" src="https://github.com/user-attachments/assets/dc2abfda-52b2-4565-9f4c-b2f5fcbf0210" />

   *Возвращаемый IP `10.0.0.2` является внутренним виртуальным IP-адресом (VIP) сети `overlay` Docker Swarm Ingress Routing Mesh.*

---

### 5. Удаление стенда

После успешной проверки работы кластера стенд и облачные ресурсы были полностью удалены:

```bash
# Остановка стека в Docker Swarm
docker stack rm python_stack

# Удаление виртуальных машин и Container Registry в Яндекс Облаке
yc compute instance delete worker-01 worker-02 manager-01
yc container registry delete --name swarm-registry
```
