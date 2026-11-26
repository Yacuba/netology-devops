# Домашнее задание к занятию «Helm»

### Задание 1. Подготовить Helm-чарт для приложения

1. В директории [task_1/netology-app](task_1/netology-app) подготовлена структура Helm-чарта для развертывания приложения.
2. Архитектура приложения разделена на два независимых компонента:
   - Frontend: веб-сервер на базе Nginx со своим Deployment и Service.
   - Backend: сетевая утилита Multitool со своим Deployment и Service.
3. Все ключевые параметры (репозитории и теги образов, порты, количество реплик) вынесены в файл переменных `values.yaml`. Это позволяет управлять версиями компонентов при релизе без правки самих манифестов.
4. Проведена проверка корректности синтаксиса чарта утилитой `helm lint`, а также протестирован рендеринг манифестов с подстановкой измененного тега образа:

```bash
helm lint task_1/netology-app && \
helm template test-release task_1/netology-app --set frontend.image.tag="1.26.0" | grep -E "image:|name:"
```

<img width="766" height="288" alt="task_1_screenshot_1" src="https://github.com/user-attachments/assets/4a9acba9-1618-4cf0-bb69-19a243793d2b" />

---

### Задание 2. Запустить две версии в разных неймспейсах

1. Подготовленный чарт развернут в трех экземплярах с передачей разных тегов образа frontend через аргумент `--set`:
   - Релиз `web-v1` установлен в пространство имен `app1` с версией Nginx `1.24.0`:
     ```bash
     helm install web-v1 task_1/netology-app \
       --namespace app1 \
       --create-namespace \
       --set frontend.image.tag="1.24.0"
     ```
   - Релиз `web-v2` установлен в то же пространство имен `app1` с версией Nginx `1.25.4`:
     ```bash
     helm install web-v2 task_1/netology-app \
       --namespace app1 \
       --set frontend.image.tag="1.25.4"
     ```
   - Релиз `web-v3` установлен в изолированное пространство имен `app2` с версией Nginx `1.26.0`:
     ```bash
     helm install web-v3 task_1/netology-app \
       --namespace app2 \
       --create-namespace \
       --set frontend.image.tag="1.26.0"
     ```

2. Корректность развертывания релизов, изоляция по неймспейсам и запущенные версии контейнеров проверены вызовом `helm` и `kubectl`:

```bash
echo "=== Список релизов Helm ===" && \
helm list -A && echo && \
echo "=== Ресурсы в namespace app1 ===" && \
kubectl get pods,svc -n app1 -o wide && echo && \
echo "=== Ресурсы в namespace app2 ===" && \
kubectl get pods,svc -n app2 -o wide && echo && \
echo "=== Проверка установленных версий образов frontend ===" && \
kubectl get pods -A -l app.kubernetes.io/component=frontend -o custom-columns="NAMESPACE:.metadata.namespace,POD:.metadata.name,IMAGE:.spec.containers[0].image"
```

<img width="1192" height="699" alt="task_2_screenshot_1" src="https://github.com/user-attachments/assets/e64518ed-0c01-4ada-ac09-5e5b1fb2c484" />
