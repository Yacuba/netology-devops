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

<img width="795" height="53" alt="task_1_screenshot_1" src="https://github.com/user-attachments/assets/d3dbd869-53f4-4929-8932-230cbf4a1424" />

3. Настроен проброс локального порта на под:

```bash
kubectl port-forward pod/hello-world 8080:8080
```

Проверка доступности веб-сервера через браузер по адресу `http://localhost:8080`:

<img width="374" height="340" alt="task_1_screenshot_2" src="https://github.com/user-attachments/assets/008a6cf0-7dbd-42eb-9556-44d371b18d3b" />

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

<img width="833" height="221" alt="task_2_screenshot_1" src="https://github.com/user-attachments/assets/6a6d7ca2-b0a3-464e-9ee8-8de132c9bc44" />

3. Настроен проброс локального порта на сервис:

```bash
kubectl port-forward svc/netology-svc 8080:80
```

<img width="340" height="124" alt="task_2_screenshot_2" src="https://github.com/user-attachments/assets/afa86bbf-baa4-45e5-8884-413284bd6bda" />

Проверка доступности сервиса через браузер по адресу `http://localhost:8080`:

<img width="368" height="336" alt="task_2_screenshot_3" src="https://github.com/user-attachments/assets/d73e4c32-5040-4403-a423-8d976d82cd8f" />
