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
