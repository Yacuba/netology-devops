# Домашнее задание к занятию «Хранение в K8s»

### Задание 1. Volume: обмен данными между контейнерами в поде

1. Подготовлен манифест Deployment [containers-data-exchange.yaml](task_1/containers-data-exchange.yaml). В поде запущены два контейнера: `busybox` и `multitool`. Для организации совместного доступа к файлам подключен эфемерный том типа `emptyDir` с точкой монтирования `/shared`.
2. Контейнер `busybox` каждые 5 секунд записывает строку с меткой времени в файл `/shared/data.txt`. Контейнер `multitool` ожидает создания файла и непрерывно читает поток данных.
3. Манифест применен в кластере. Параметры пода и подключение тома `shared-storage` к обоим контейнерам проверены командой `describe`:

```bash
kubectl describe pod -l app=data-exchange | grep -E "Name:|Containers:|busybox:|multitool:|Mounts:|/shared|Volumes:|shared-storage:|Type:"
```

<img width="706" height="309" alt="task_1_screenshot_1" src="https://github.com/user-attachments/assets/4d9f95b4-8878-4481-8496-56c59aa0145b" />

4. Передача данных между контейнерами проверена чтением общего файла из контейнера `multitool`:

```bash
kubectl exec -it <pod-name> -c multitool -- tail -f /shared/data.txt
```

<img width="649" height="204" alt="task_1_screenshot_2" src="https://github.com/user-attachments/assets/5ab12efe-6100-4aa0-baf6-90d3d7363c9d" />

---

### Задание 2. PV, PVC

1. Подготовлен манифест [pv-pvc.yaml](task_2/pv-pvc.yaml). В нем описаны три связанных ресурса:
   - `PersistentVolume` (`local-pv`) объемом 1Gi с типом хранилища `hostPath` (`/data/pv-storage`), режимом доступа `ReadWriteOnce` и политикой очистки `Retain`.
   - `PersistentVolumeClaim` (`local-pvc`), запрашивающий 1Gi и привязанный к созданному PV через директиву `volumeName`.
   - `Deployment` (`data-exchange-pvc`) с контейнерами `busybox` и `multitool`, монтирующий PVC в каталог `/shared`.

2. Манифест применен в кластере. Статусы связывания хранилища и нода размещения пода проверены командой `get`:

```bash
kubectl get pv,pvc && kubectl get pods -l app=data-exchange-pvc -o wide
```

<img width="1072" height="136" alt="task_2_screenshot_1" src="https://github.com/user-attachments/assets/de5f737e-0a2e-4462-b400-6aac00564986" />

Ресурсы перешли в состояние `Bound`. Под запустился на ноде `node-2`.

3. Чтение данных контейнером `multitool` из постоянного тома проверено через вызов утилиты `tail`:

```bash
kubectl exec -it <pod-name> -c multitool -- tail -f /shared/data.txt
```

<img width="667" height="224" alt="task_2_screenshot_2" src="https://github.com/user-attachments/assets/7b0c81f0-e265-4e53-9d53-7ae7baef7521" />

4. Выполнено удаление Deployment и PVC, после чего проверен статус постоянного тома:

```bash
kubectl delete deployment data-exchange-pvc && kubectl delete pvc local-pvc
kubectl describe pv local-pv
```

<img width="418" height="323" alt="task_2_screenshot_3" src="https://github.com/user-attachments/assets/bd9f2d53-4683-47cd-8f34-ed1940b60ed7" />

Том перешел в статус `Released`. Такое поведение обусловлено политикой очистки `persistentVolumeReclaimPolicy: Retain`. Kubernetes защищает данные от перезаписи. В спецификации тома сохраняется ссылка на удаленный клейм (`Claim: default/local-pvc`). Том считается освобожденным, но не доступен для автоматического переиспользования другими PVC до ручного сброса администратором.

5. Проверено наличие данных на диске ноды `node-2`, после чего объект PV удален из кластера:

```bash
kubectl delete pv local-pv && \
ssh yc-user@153.51.174.225 "ls -la /data/pv-storage && tail -n 5 /data/pv-storage/data.txt"
```

<img width="659" height="204" alt="task_2_screenshot_4" src="https://github.com/user-attachments/assets/2f0058d5-c962-4075-b439-c872d573c690" />

Файл `data.txt` остался на файловой системе ноды `node-2`. Механизм `hostPath` монтирует реальную директорию хоста напрямую. Kubernetes оперирует лишь абстракцией объекта PV в памяти API-сервера. При удалении этой абстракции кластер не трогает файлы на локальном носителе операционной системы.

---

### Задание 3. StorageClass

1. Подготовлен манифест [sc.yaml](task_3/sc.yaml). В файле объединены конфигурации:
   - `StorageClass` с именем `local-storage`, провижинером `kubernetes.io/no-provisioner` и режимом отложенного связывания `volumeBindingMode: WaitForFirstConsumer`.
   - `PersistentVolume` (`sc-pv`) с указанием класса `local-storage` и директорией `hostPath: /data/sc-storage`.
   - `PersistentVolumeClaim` (`sc-pvc`), запрашивающий том объемом 1Gi из созданного класса.
   - `Deployment` (`data-exchange-sc`) с контейнерами `busybox` и `multitool`, монтирующий постоянный том в каталог `/shared`.

2. Манифест развернут в кластере. Корректность создания класса, связывания томов и старта пода проверена выводом команды `get`:

```bash
kubectl get sc,pv,pvc && kubectl get pods -l app=data-exchange-sc -o wide
```

<img width="1030" height="189" alt="task_3_screenshot_1" src="https://github.com/user-attachments/assets/73757d08-7892-4729-b0ed-5f455f9b1ca9" />

3. Чтение файла контейнером `multitool` в реальном времени проверено через вызов утилиты `tail`:

```bash
kubectl exec -it <pod-name> -c multitool -- tail -f /shared/data.txt
```

<img width="992" height="231" alt="task_3_screenshot_2" src="https://github.com/user-attachments/assets/41d01655-d249-4bcc-b277-8d2eea292255" />
