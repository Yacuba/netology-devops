# Домашнее задание к занятию «Запуск приложений в K8S»

### Задание 1. Создать Deployment и обеспечить доступ к репликам приложения из другого Pod

1. Подготовлен начальный манифест [deployment.yaml](deployment.yaml) с двумя контейнерами в одном поде: `nginx` и `multitool`. Так как оба приложения по умолчанию занимают 80 порт общего сетевого пространства пода, контейнер `multitool` завершился с ошибкой:

```bash
kubectl apply -f deployment.yaml
kubectl get pods
kubectl logs -l app=web-multitool -c multitool
```

<img width="583" height="240" alt="task_1_screenshot_1" src="https://github.com/user-attachments/assets/c9ef05b3-40f9-41d0-91a4-8ca786b849cc" />

2. Для устранения коллизии конфигурация multitool дополнена переменной окружения `HTTP_PORT: "8080"`. Обновленный манифест применен в кластере. Под перешел в статус `Running` с готовностью обоих контейнеров (2/2):

```bash
kubectl apply -f deployment.yaml
kubectl get pods -o wide
```

<img width="909" height="51" alt="task_1_screenshot_2" src="https://github.com/user-attachments/assets/b26413cf-51e2-4896-9cfe-380f8026f879" />

3. Выполнено масштабирование Deployment до двух реплик:

```bash
kubectl scale deployment netology-deployment --replicas=2
kubectl get pods -o wide
```

Планировщик распределил реплики по рабочим нодам `node-1` и `node-2`:

<img width="926" height="68" alt="task_1_screenshot_3" src="https://github.com/user-attachments/assets/b71d3b9e-ec21-4938-b166-973c5049d0c4" />

4. Подготовлен манифест сервиса [service.yaml](service.yaml) типа `ClusterIP`. Сервис перенаправляет порт 80 на nginx и порт 8080 на multitool по селектору `app: web-multitool`:

```bash
kubectl apply -f service.yaml
kubectl get svc,endpoints netology-svc
```

5. Подготовлен манифест отдельного пода-клиента [multitool-client.yaml](multitool-client.yaml). Сетевая доступность обеих служб проверена через `curl` по DNS-имени сервиса:

```bash
kubectl apply -f multitool-client.yaml
kubectl exec -it multitool-client -- curl -i http://netology-svc:80
kubectl exec -it multitool-client -- curl -i http://netology-svc:8080
```

<img width="601" height="307" alt="task_1_screenshot_4" src="https://github.com/user-attachments/assets/cc568c01-023b-4efa-9d96-1c7a0e6440ce" />

### Задание 2. Создать Deployment и обеспечить старт основного контейнера при выполнении условий

1. Подготовлен манифест Deployment [init-deployment.yaml](init-deployment.yaml) для приложения nginx. В секцию `initContainers` добавлен контейнер на базе `busybox`, выполняющий опрос доступности DNS-имени сервиса через команду `nslookup`:

```bash
kubectl apply -f init-deployment.yaml
```

2. До запуска сервиса основной контейнер не стартует. Под находится в состоянии `Init:0/1`, а в логах Init-контейнера фиксируются попытки резолвинга имени:

```bash
kubectl get pods -l app=nginx-init
kubectl logs -l app=nginx-init -c wait-for-service --tail=8
```

<img width="709" height="186" alt="task_2_screenshot_1" src="https://github.com/user-attachments/assets/8468824a-dbe1-4087-8a58-3b4b741047eb" />

3. Подготовлен манифест сервиса [nginx-service.yaml](nginx-service.yaml) типа `ClusterIP`. Манифест применен в кластере:

```bash
kubectl apply -f nginx-service.yaml
```

4. После появления сервиса в кластере `nslookup` разрешает имя. Init-контейнер завершает работу, а под приложения переходит в статус `Running` (1/1):

```bash
kubectl get svc nginx-service && kubectl get pods -l app=nginx-init -o wide
```

<img width="934" height="86" alt="task_2_screenshot_2" src="https://github.com/user-attachments/assets/0dbdd04a-c4e3-435f-ac68-39fc82c9b020" />
