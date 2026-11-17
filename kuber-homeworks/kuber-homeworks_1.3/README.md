# Домашнее задание к занятию «Запуск приложений в K8S»

### Задание 1. Создать Deployment и обеспечить доступ к репликам приложения из другого Pod

1. Подготовлен начальный манифест [deployment.yaml](deployment.yaml) с двумя контейнерами в одном поде: `nginx` и `multitool`. Так как оба приложения по умолчанию занимают 80 порт общего сетевого пространства пода, контейнер `multitool` завершился с ошибкой:

```bash
kubectl apply -f deployment.yaml
kubectl get pods
kubectl logs -l app=web-multitool -c multitool
```

![Ошибка запуска контейнера multitool из-за конфликта 80 порта](task_1_screenshot_1)

2. Для устранения коллизии конфигурация multitool дополнена переменной окружения `HTTP_PORT: "8080"`. Обновленный манифест применен в кластере. Под перешел в статус `Running` с готовностью обоих контейнеров (2/2):

```bash
kubectl apply -f deployment.yaml
kubectl get pods -o wide
```

![Работающий под с двумя контейнерами до масштабирования](task_1_screenshot_2)

3. Выполнено масштабирование Deployment до двух реплик:

```bash
kubectl scale deployment netology-deployment --replicas=2
kubectl get pods -o wide
```

Планировщик распределил реплики по рабочим нодам `node-1` и `node-2`:

![Состояние подов после масштабирования до двух реплик](task_1_screenshot_3)

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

![Проверка сетевой доступности через curl из отдельного пода](task_1_screenshot_4)

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

![Состояние пода Init:0/1 и ожидание сервиса в логах Init-контейнера](task_2_screenshot_1)

3. Подготовлен манифест сервиса [nginx-service.yaml](nginx-service.yaml) типа `ClusterIP`. Манифест применен в кластере:

```bash
kubectl apply -f nginx-service.yaml
```

4. После появления сервиса в кластере `nslookup` разрешает имя. Init-контейнер завершает работу, а под приложения переходит в статус `Running` (1/1):

```bash
kubectl get svc nginx-service && kubectl get pods -l app=nginx-init -o wide
```

![Успешный запуск пода и активный сервис nginx-service](task_2_screenshot_2)