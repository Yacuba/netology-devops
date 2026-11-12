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

<img width="402" height="86" alt="task_1_screenshot_1" src="https://github.com/user-attachments/assets/77c0354f-959a-4170-9064-b08b997d64e1" />

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

<img width="977" height="271" alt="task_1_screenshot_2" src="https://github.com/user-attachments/assets/d5797383-9cf2-4fe1-a6d1-a7242d0d2a69" />

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

<img width="981" height="52" alt="task_2_screenshot_1" src="https://github.com/user-attachments/assets/f597b0e4-b522-4dc8-b621-8f66e0bd9501" />

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

<img width="639" height="292" alt="task_2_screenshot_2" src="https://github.com/user-attachments/assets/cf68ff9c-0e5c-4104-9f14-f29de5332f56" />
