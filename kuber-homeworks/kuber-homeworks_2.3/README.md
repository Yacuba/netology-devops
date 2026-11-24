# Домашнее задание к занятию «Настройка приложений и управление доступом в Kubernetes»

### Задание 1. Работа с ConfigMaps

1. Подготовлен манифест [configmap-web.yaml](task_1/configmap-web.yaml). В объекте ConfigMap определены порты (`HTTP_PORT: "8080"`, `HTTPS_PORT: "11443"`) для сетевой утилиты multitool, а также разметка страницы `index.html`. Это устраняет конфликт стандартного 80 порта между сервисами внутри одного сетевого пространства пода.
2. Подготовлен манифест Deployment [deployment.yaml](task_1/deployment.yaml) с двумя контейнерами:
   - `nginx` слушает порт 80. Файл `index.html` монтируется через том ConfigMap в каталог `/usr/share/nginx/html`.
   - `multitool` считывает кастомные порты из ConfigMap через директиву `valueFrom.configMapKeyRef`. В результате multitool слушает порт 8080 и не блокирует запуск nginx.
3. Манифесты развернуты в кластере. Статус пода перешел в состояние `2/2 Running`. Доступность веб-страницы проверена отправкой HTTP-запроса через утилиту `curl` из контейнера multitool на локальный адрес `nginx`:

```bash
kubectl get cm,deploy,pod -l app=web-app &&
kubectl exec deployment/web-app -c multitool -- curl -s http://localhost:80
```

![Проверка статуса пода и отдача страницы из ConfigMap через curl](task_1_screenshot_1)

---

### Задание 2. Настройка HTTPS с Secrets

1. В кластере активирован контроллер ingress:

```bash
microk8s enable ingress
```

2. Сгенерирован самоподписанный SSL-сертификат и приватный RSA-ключ для домена `myapp.example.com`:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout task_2/tls.key \
  -out task_2/tls.crt \
  -subj "/CN=myapp.example.com"
```

3. Подготовлен манифест секрета [secret-tls.yaml](task_2/secret-tls.yaml) с типом `kubernetes.io/tls`. Конфигурация сформирована на базе сгенерированных файлов:

```bash
kubectl create secret tls tls-secret \
  --cert=task_2/tls.crt \
  --key=task_2/tls.key \
  --dry-run=client -o yaml > task_2/secret-tls.yaml
```

4. Подготовлен манифест [ingress-tls.yaml](task_2/ingress-tls.yaml). В файле объединены:
   - Сервис `web-service`, направляющий трафик на поды с селектором `app: web-app`.
   - Ресурс `Ingress` с ingress-классом `public`. В блоке `tls` указан домен `myapp.example.com` и привязан созданный секрет `tls-secret`.

5. Манифесты развернуты в кластере. Корректность TLS-терминации проверена вызовом `curl` с игнорированием неподписанного сертификата (`-k`) и ручным резолвом домена на внешний IP ноды:

```bash
kubectl get secret tls-secret && \
kubectl get ingress web-ingress && \
echo "--- HTTPS запрос через curl ---" && \
curl -k -s -i --resolve myapp.example.com:443:153.51.175.6 https://myapp.example.com
```

![Проверка статуса Secret, Ingress и HTTPS-ответа через curl](task_2_screenshot_1)

---

### Задание 3. Настройка RBAC

1. В кластере MicroK8S активирован модуль управления доступом RBAC:

```bash
microk8s enable rbac
```

2. Сгенерирован закрытый ключ и запрос на сертификат (CSR) для пользователя `developer`:

```bash
openssl genrsa -out task_3/developer.key 2048
openssl req -new -key task_3/developer.key -out task_3/developer.csr -subj "/CN=developer"
```

Сертификат подписан корневым центром сертификации (CA) кластера MicroK8S:

```bash
openssl x509 -req -in developer.csr \
  -CA /var/snap/microk8s/current/certs/ca.crt \
  -CAkey /var/snap/microk8s/current/certs/ca.key \
  -CAcreateserial -out developer.crt -days 365
```

3. Подготовлен манифест роли [role-pod-reader.yaml](task_3/role-pod-reader.yaml). Роль `pod-reader` в пространстве имен `default` предоставляет доступ к ресурсам `pods` и `pods/log` только на чтение (`get`, `list`, `watch`).
4. Подготовлен манифест [rolebinding-developer.yaml](task_3/rolebinding-developer.yaml). Привязка связывает пользователя `developer` с созданной ролью `pod-reader`.
5. Манифесты применены в кластере. Корректность изоляции прав проверена через механизм имперсонации `--as=developer`:

```bash
echo "=== 1. Проверка списка подов (разрешено) ===" && \
kubectl get pods --as=developer && echo && \
echo "=== 2. Проверка чтения логов пода (разрешено) ===" && \
POD_NAME=$(kubectl get pods -l app=web-app -o jsonpath='{.items[0].metadata.name}') && \
kubectl logs $POD_NAME -c nginx --tail=2 --as=developer && echo && \
echo "=== 3. Попытка запросить deployments (Forbidden) ===" && \
kubectl get deployments --as=developer ; echo && \
echo "=== 4. Попытка удалить под (Forbidden) ===" && \
kubectl delete pod $POD_NAME --as=developer
```

![Проверка прав пользователя developer через RBAC](task_3_screenshot_1)