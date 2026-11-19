# Домашнее задание к занятию «Сетевое взаимодействие в Kubernetes»

### Задание 1. Настройка Service (ClusterIP и NodePort)

1. Подготовлен манифест Deployment [deployment-multi-container.yaml](task_1/deployment-multi-container.yaml) на 3 реплики с двумя контейнерами в поде: `nginx` (порт 80) и `multitool` (порт 8080 через переменную `HTTP_PORT`).
2. Подготовлен манифест сервиса [service-clusterip.yaml](task_1/service-clusterip.yaml) типа `ClusterIP`. Сервис перенаправляет порт 9001 на `nginx` и порт 9002 на `multitool`. Манифесты развернуты в кластере.
3. Доступность обоих приложений проверена изнутри кластера через временный под с утилитой `curl`:

```bash
kubectl run test-pod --image=wbitt/network-multitool --rm -it -- sh
curl -i service-clusterip:9001 | head -n 7
curl -i service-clusterip:9002 | head -n 7
```

![Проверка доступности ClusterIP изнутри кластера](task_1_screenshot_1)

4. Подготовлен манифест сервиса [service-nodeport.yaml](task_1/service-nodeport.yaml) типа `NodePort`. Сервис открывает доступ к `nginx` на статическом порту нод `30080`.
5. Доступ к веб-серверу проверен внешними запросами к публичным IP-адресам обеих нод кластера:

```bash
kubectl get svc service-nodeport
curl -i http://153.51.175.223:30080 | head -n 7
curl -i http://81.26.191.114:30080 | head -n 7
```

![Проверка доступности сервиса NodePort через внешние IP нод](task_1_screenshot_2)

---

### Задание 2. Настройка Ingress

1. В кластере активирован контроллер Ingress через команду `microk8s enable ingress`.
2. Подготовлены манифесты развертывания веб-приложений:
   - Frontend на базе Nginx: [deployment-frontend.yaml](task_2/deployment-frontend.yaml) и сервис [service-frontend.yaml](task_2/service-frontend.yaml).
   - Backend на базе MultiTool: [deployment-backend.yaml](task_2/deployment-backend.yaml) и сервис [service-backend.yaml](task_2/service-backend.yaml).
3. Подготовлен манифест [ingress.yaml](task_2/ingress.yaml). Для корректного удаления префикса пути `/api` перед отправкой в бэкенд настроен ресурс `Middleware` типа `stripPrefix`, а правила маршрутизации распределяют входящий трафик:
   - Путь `/` перенаправляет запросы на сервис `service-frontend`.
   - Путь `/api` перенаправляет запросы на сервис `service-backend`.
4. Манифесты применены в кластере. Корректность распределения трафика проверена внешними HTTP-запросами к публичному IP ноды:

```bash
kubectl get ingress app-ingress
curl -i http://153.51.175.223/ | head -n 7
curl -i http://153.51.175.223/api | head -n 7
```

![Проверка маршрутизации Ingress по путям / и /api](task_2_screenshot_1)