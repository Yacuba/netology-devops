# Домашнее задание к занятию «Базовые объекты K8S»

### Задание 1. Создать Pod с именем hello-world

1. Подготовлен манифест пода [hello-world.yaml](hello-world.yaml) с образом `gcr.io/kubernetes-e2e-test-images/echoserver:2.2`.

2. Манифест применен в кластере:

```bash
kubectl apply -f hello-world.yaml
```

Проверка состояния и IP-адреса пода:

```bash
kubectl get pods -o wide
```

![Вывод команды kubectl get pods](task_1_screenshot_1)

3. Настроен проброс локального порта на под:

```bash
kubectl port-forward pod/hello-world 8080:8080
```

Проверка доступности веб-сервера через браузер по адресу `http://localhost:8080`:

![Результат подключения к Pod через браузер](task_1_screenshot_2)

### Задание 2. Создать Service и подключить его к Pod

1. Подготовлены манифесты пода [netology-web-pod.yaml](netology-web-pod.yaml) и сервиса [netology-svc.yaml](netology-svc.yaml). Сервис перенаправляет внешний порт 80 на внутренний порт 8080 пода через селектор `app: netology-web`.

2. Манифесты применены в кластере:

```bash
kubectl apply -f netology-web-pod.yaml
kubectl apply -f netology-svc.yaml
```

Проверка состояния пода, сервиса и привязанных эндпоинтов:

```bash
kubectl get pods,svc,endpoints -o wide
```

![Вывод команды kubectl get pods,svc,endpoints](task_2_screenshot_1)

3. Настроен проброс локального порта на сервис:

```bash
kubectl port-forward svc/netology-svc 8080:80
```

![Процесс работы команды kubectl port-forward](task_2_screenshot_2)

Проверка доступности сервиса через браузер по адресу `http://localhost:8080`:

![Результат подключения к Service через браузер](task_2_screenshot_3)