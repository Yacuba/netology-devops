# Домашнее задание к занятию «Kubernetes. Причины появления. Команда kubectl»

### Задание 1. Установка MicroK8S

Для выполнения работы подготовлена виртуальная машина в Yandex Cloud (Ubuntu 22.04 LTS).

1. Установлен пакет MicroK8s через менеджер snap, права текущего пользователя настроены для работы с кластером:

```bash
sudo apt update && sudo apt install -y snapd
sudo snap install microk8s --classic
sudo usermod -a -G microk8s $USER
mkdir -p ~/.kube
sudo chown -f -R $USER ~/.kube
```

Проверка статуса готовности кластера:

```bash
microk8s status --wait-ready
```

![Статус MicroK8S после первичной установки](task_1_screenshot_1)

2. В кластере включены необходимые дополнения DNS и Dashboard:

```bash
microk8s enable dns dashboard
```

3. Для возможности безопасного внешнего подключения публичный адрес виртуальной машины (`153.51.168.222`) добавлен в шаблон конфигурации `/var/snap/microk8s/current/certs/csr.conf.template` в секцию `[ alt_names ]`:

```text
IP.100 = 153.51.168.222
```

Сертификаты API-сервера и прокси перевыпущены:

```bash
sudo microk8s refresh-certs --cert server.crt
sudo microk8s refresh-certs --cert front-proxy-client.crt
```

Проверка состояния системных подов кластера и содержимого поля Subject Alternative Name (SAN) обновленного сертификата:

```bash
microk8s kubectl get pods -A
openssl x509 -noout -text -in /var/snap/microk8s/current/certs/server.crt | grep -A 2 "Subject Alternative Name"
```

![Список работающих подов Dashboard и проверка SAN сертификата](task_1_screenshot_2)

### Задание 2. Установка и настройка локального kubectl

1. На локальную рабочую станцию установлена утилита `kubectl` и активировано автодополнение bash:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
```

2. Конфигурационный файл кластера выгружен с удаленного хоста, приватный IP заменен на внешний публичный адрес:

```bash
mkdir -p ~/.kube
ssh yc-user@153.51.168.222 "microk8s config" > ~/.kube/config
chmod 600 ~/.kube/config
sed -i 's/10.130.0.13/153.51.168.222/g' ~/.kube/config
```

Проверка связи локального клиента с кластером:

```bash
kubectl get nodes -o wide
```

![Вывод команды kubectl get nodes на локальной машине](task_2_screenshot_1)

3. Для доступа к веб-интерфейсу создан административный сервисный аккаунт и сгенерирован токен авторизации:

```bash
kubectl create serviceaccount admin-user -n kubernetes-dashboard
kubectl create clusterrolebinding admin-user --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
kubectl create token admin-user -n kubernetes-dashboard --duration=24h
```

Запущен сетевой туннель к сервису шлюза Dashboard:

```bash
kubectl port-forward -n kubernetes-dashboard svc/kubernetes-dashboard-kong-proxy 10443:443 --address 0.0.0.0
```

Вход в панель управления через браузер по адресу `https://127.0.0.1:10443` с использованием сгенерированного токена:

![Интерфейс Kubernetes Dashboard в браузере](task_2_screenshot_2)