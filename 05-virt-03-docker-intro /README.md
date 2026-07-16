# Домашнее задание к занятию 4 «Оркестрация группой Docker контейнеров на примере Docker Compose»

## Задача 1

1. **Установка Docker и Docker Compose Plugin**  
   Docker и плагин Docker Compose были успешно установлены на виртуальную машину под управлением Ubuntu Server 24.04 LTS.

2. **Скачивание базового образа**  
   Был скачан официальный образ `nginx:1.29.0` с помощью команды:
   ```bash
   docker pull nginx:1.29.0
   ```
   
   <img width="728" height="290" alt="Снимок экрана 2026-07-14 161526" src="https://github.com/user-attachments/assets/1a8e6acb-02a6-43ce-b6ea-fd0bbdbb2845" />

3. **Создание конфигурационных файлов**  
   Была создана рабочая директория `~/custom-nginx`, в которой подготовлены файлы:
   * `index.html` с приветственным текстом.
   * `Dockerfile` для сборки кастомного образа.
   
   Проверка содержимого файлов:
   
   <img width="447" height="253" alt="Снимок экрана 2026-07-14 161955" src="https://github.com/user-attachments/assets/cdd95cc5-16e1-4f60-96c9-47fd48918712" />

4. **Подготовка репозитория на Docker Hub**
   В Docker Hub был создан публичный репозиторий `yacuba/custom-nginx`:
   
   <img width="395" height="260" alt="Снимок экрана 2026-07-14 162900" src="https://github.com/user-attachments/assets/c7d32523-0835-49b3-9a29-58d876bd52f6" />

5. **Сборка и отправка образа**  
   Образ был успешно собран локально, тегирован и отправлен в Docker Hub командами:
   ```bash
   docker build -t yacuba/custom-nginx:1.0.0 .
   docker login
   docker push yacuba/custom-nginx:1.0.0
   ```
   
   <img width="880" height="275" alt="Снимок экрана 2026-07-14 162929" src="https://github.com/user-attachments/assets/835af6f3-83e8-4d06-a934-5522308c7703" />

   Отображение отправленного тега `1.0.0` в веб-интерфейсе Docker Hub:
   
   <img width="612" height="641" alt="Снимок экрана 2026-07-14 162948" src="https://github.com/user-attachments/assets/cb5efffc-7ac2-4a47-973e-7ea364d44b98" />

6. **Ссылка на публичный репозиторий:**  
   [https://hub.docker.com/r/yacuba/custom-nginx/general](https://hub.docker.com/repository/docker/yacuba/custom-nginx/general)

## Задача 2

1. **Запуск контейнера**  
   Контейнер на основе собранного образа `yacuba/custom-nginx:1.0.0` был запущен в фоновом режиме с именем `yakuba-custom-nginx-t2` и привязкой к порту `127.0.0.1:8080`:
  ```bash
  docker run -d --name yakuba-custom-nginx-t2 -p 127.0.0.1:8080:80 yacuba/custom-nginx:1.0.0
  ```
      
2. **Переименование контейнера**  
   Контейнер был переименован без остановки и удаления в `custom-nginx-t2`:
  ```bash
  docker rename yakuba-custom-nginx-t2 custom-nginx-t2
  ```

  <img width="1087" height="60" alt="Снимок экрана 2026-07-14 170350" src="https://github.com/user-attachments/assets/b4325b9a-27d5-4e81-b438-1a2585620b83" />

3. **Сбор диагностических данных**  
   Была выполнена диагностическая команда для проверки состояния запущенного контейнера, прослушиваемых портов хост-системы, логов и содержимого индекс-страницы в формате Base64:
   ```bash
   date +"%d-%m-%Y %T.%N %Z" ; sleep 0.150 ; docker ps ; ss -tlpn | grep 127.0.0.1:8080  ; docker logs custom-nginx-t2 -n1 ; docker exec -it custom-nginx-t2 base64 /usr/share/nginx/html/index.html
   ```

4. **Проверка доступности страницы**  
   Проверка доступности страницы с помощью утилиты `curl` подтвердила корректную отдачу кастомного HTML-кода:
   <pre><code>curl http://127.0.0.1:8080</code></pre>
   
   <img width="1103" height="383" alt="Снимок экрана 2026-07-14 170513" src="https://github.com/user-attachments/assets/2e4c3342-3bd1-4cd7-96b9-f17c4f4a6f33" />

## Задача 3

1. **Подключение к стандартным потокам ввода/вывода/ошибок**  
   Для подключения к потокам запущенного контейнера использовалась команда:
   ```bash
   docker attach custom-nginx-t2
   ```

2. **Остановка контейнера комбинацией Ctrl-C**  
   После подключения к потокам контейнера была нажата комбинация клавиш `Ctrl+C`, что привело к завершению работы контейнера.

3. **Объяснение остановки контейнера**  
   Контейнер остановился, так как комбинация `Ctrl+C` отправила сигнал прерывания `SIGINT` основному процессу веб-сервера Nginx (PID 1), работавшему на переднем плане. Поскольку Docker-контейнер существует только до тех пор, пока активен его главный процесс, завершение работы Nginx привело к автоматической остановке всего контейнера.
   
   <img width="1264" height="476" alt="Снимок экрана 2026-07-14 171952" src="https://github.com/user-attachments/assets/5f266e3d-f1d9-45be-8434-6a17e548bdfa" />

4. **Перезапуск контейнера**  
   Контейнер был снова запущен командой:
   ```bash
   docker start custom-nginx-t2
   ```

5. **Редактирование конфигурации Nginx внутри контейнера**  
   Был выполнен вход в интерактивный терминал контейнера, обновлен список пакетов и установлен текстовый редактор `nano`:
   ```bash
   docker exec -it custom-nginx-t2 bash
   apt-get update && apt-get install -y nano
   ```

   В файле `/etc/nginx/conf.d/default.conf` порт прослушивания был изменен с `listen 80` на `listen 81`. Настройки были применены командой:
   ```bash
   nginx -s reload
   ```

   Проверка доступности портов изнутри контейнера с помощью `curl`:
   * `http://127.0.0.1:80` — недоступен (Connection refused).
   * `http://127.0.0.1:81` — успешно возвращает кастомную страницу.
   
   <img width="800" height="290" alt="Снимок экрана 2026-07-14 172501" src="https://github.com/user-attachments/assets/af151a02-c480-43fb-a61e-c2665c887cf2" />

6. **Проверка портов на хост-системе**  
   После выхода из контейнера на хост-системе были выполнены проверочные команды:
   ```bash
   ss -tlpn | grep 127.0.0.1:8080
   docker port custom-nginx-t2
   curl http://127.0.0.1:8080
   ```
   
   <img width="540" height="116" alt="Снимок экрана 2026-07-14 172729" src="https://github.com/user-attachments/assets/d4a6eb62-30b2-4a66-9339-801ba4e184a9" />

   **Суть возникшей проблемы:**
   Docker-прокси на хосте продолжает слушать порт `8080` и перенаправлять трафик на порт `80` внутри контейнера. Однако внутри контейнера Nginx больше не слушает порт `80` (он был переведен на порт `81`). В результате запросы к `127.0.0.1:8080` на хосте завершаются ошибкой связи.

7. **Решение проблемы с доступностью**  
   Для исправления маппинга без удаления контейнера и без изменения конфигурации Nginx были отредактированы файлы конфигурации Docker на хосте:
   * Служба Docker была остановлена: `sudo systemctl stop docker docker.socket`.
   * В файлах `/var/lib/docker/containers/<container_id>/hostconfig.json` и `config.v2.json` порт назначения внутри контейнера был изменен с `80/tcp` на `81/tcp`.
   * Служба Docker была запущена: `sudo systemctl start docker`.
   * После запуска контейнера `docker port` подтвердил новый маппинг `81/tcp -> 127.0.0.1:8080`, а `curl http://127.0.0.1:8080` с хоста стал успешно возвращать страницу.
   
   <img width="509" height="212" alt="Снимок экрана 2026-07-14 173848" src="https://github.com/user-attachments/assets/eb59ffcd-99da-47f6-9eac-d2ecc2090f68" />

8. **Принудительное удаление контейнера**  
   Контейнер был принудительно удален в запущенном состоянии с помощью флага `-f` (`--force`):
   ```bash
   docker rm -f custom-nginx-t2
   ```
   
   <img width="654" height="97" alt="Снимок экрана 2026-07-14 173958" src="https://github.com/user-attachments/assets/b1f61893-c2e4-44c9-a708-e16cf2154506" />

## Задача 4

В рамках данной задачи была изучена работа с общими томами (Bind Mounts) для обмена данными между хост-системой и несколькими контейнерами.

1. **Запуск контейнеров с общим томом**  
   Были запущены два контейнера из образов `centos:7` и `debian:latest`. Текущий рабочий каталог хоста `$(pwd)` (`~/task4`) был смонтирован в директорию `/data` каждого из контейнеров:
   ```bash
   docker run -dt --name centos-t4 -v $(pwd):/data centos:7
   docker run -dt --name debian-t4 -v $(pwd):/data debian:latest
   ```
   
   <img width="891" height="384" alt="Снимок экрана 2026-07-16 151514" src="https://github.com/user-attachments/assets/4cae8a28-e599-4d80-b89c-2ab8919e5134" />

2. **Создание файлов**  
   * Изнутри первого контейнера (`centos-t4`) был создан файл `/data/centos_file.txt`:
     ```bash
     docker exec -it centos-t4 bash
     echo 'It is CentOS file!' > /data/centos_file.txt
     exit
     ```
   * На хостовой машине в текущем каталоге `~/task4` был создан файл `host_file.txt`:
     ```bash
     echo 'It is Host file!' > host_file.txt
     ```

3. **Проверка общего доступа во втором контейнере**  
   Был выполнен вход во второй контейнер (`debian-t4`) для проверки наличия и содержимого созданных файлов в директории `/data`:
   ```bash
   docker exec -it debian-t4 bash
   ls -la /data
   cat /data/centos_file.txt /data/host_file.txt
   exit
   ```
   
   <img width="616" height="191" alt="Снимок экрана 2026-07-16 152406" src="https://github.com/user-attachments/assets/29c8b444-f75f-4221-8d3d-b48137997f2c" />

   Оба файла успешно отображаются и читаются внутри контейнера Debian. Это подтверждает, что изменения в смонтированной директории мгновенно синхронизируются между хостом и всеми подключенными контейнерами.

## Задача 5

1. **Первоначальный запуск проекта**  
   В директории `/tmp/netology/docker/task5` были созданы два файла: `compose.yaml` (описывающий сервис Portainer) и `docker-compose.yaml` (описывающий локальный Registry). При выполнении команды `docker compose up -d` запустился только файл **`compose.yaml`**.
   
   <img width="1321" height="267" alt="Снимок экрана 2026-07-16 154110" src="https://github.com/user-attachments/assets/da5d0aca-f033-4f51-8c20-d9c9df2bd9e4" />

   Согласно спецификации Docker Compose, имя `compose.yaml` является приоритетным стандартом по умолчанию. Если в одной директории находятся файлы с именами `compose.yaml` и `docker-compose.yaml`, утилита Compose всегда выбирает и запускает приоритетный `compose.yaml`, игнорируя второй файл.

2. **Объединение файлов через директиву `include`**  
   Файл `compose.yaml` был отредактирован для автоматического подключения `docker-compose.yaml`:
   <pre><code>include:
  - docker-compose.yaml

services:
  portainer:
    network_mode: host
    image: portainer/portainer-ce:latest
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock</code></pre>

3. **Загрузка кастомного образа в локальный Registry**  
   После повторного запуска проекта (запустились оба контейнера) кастомный образ `yacuba/custom-nginx:1.0.0` был тегирован и успешно отправлен в локальный реестр:
   ```bash   
   docker tag yacuba/custom-nginx:1.0.0 127.0.0.1:5000/custom-nginx:latest
   docker push 127.0.0.1:5000/custom-nginx:latest
   docker compose up -d
   ```
   
   <img width="1327" height="420" alt="Снимок экрана 2026-07-16 155900" src="https://github.com/user-attachments/assets/42c9a93d-b1f1-4c00-8e8b-b44f273f5d7c" />

4. **Деплой стека в Portainer**  
   Был выполнен вход в Portainer по адресу `http://<IP_ВМ>:9000` с хостовой ОС. В локальном окружении во вкладке **Stacks** был развернут стек со следующим манифестом:
   <pre><code>version: '3'

services:
  nginx:
    image: 127.0.0.1:5000/custom-nginx
    ports:
      - "9090:80"</code></pre>
   
   <img width="918" height="282" alt="Снимок экрана 2026-07-16 161154" src="https://github.com/user-attachments/assets/5a0fe3c6-d68c-47bd-a0ec-787e790df4ac" />

5. **Инспектирование контейнера в Portainer**  
   В разделе **Containers** был выбран запущенный контейнер Nginx. Скриншот параметров инспектирования в представлении `<>` Tree:
   
   <img width="818" height="1075" alt="Снимок экрана 2026-07-16 161802" src="https://github.com/user-attachments/assets/9a5760f8-ea7c-4826-8227-edec5294c45f" />

6. **Удаление манифеста и завершение работы**  
   Файл `compose.yaml` был удален, после чего выполнена команда обновления проекта:
   ```bash
   rm compose.yaml
   docker compose up -d
   ```

   **Суть предупреждения:**  
   Поскольку `compose.yaml` удален, Docker Compose теперь считывает только оставшийся файл `docker-compose.yaml`, где описан только сервис `registry`. Compose обнаруживает, что контейнер Portainer, запущенный ранее в рамках этого же проекта, теперь отсутствует в текущей конфигурации и классифицирует его как «осиротевший» (orphan) и рекомендует использовать флаг `--remove-orphans` для его удаления.

   **Выполненные действия:**  
   * Осиротевший контейнер Portainer был удален командой:
     ```bash
     docker compose up -d --remove-orphans
     ```
   * Весь проект был успешно остановлен и удален одной командой:
     ```bash
     docker compose down
     ```
   
   <img width="1320" height="383" alt="Снимок экрана 2026-07-16 162153" src="https://github.com/user-attachments/assets/39659351-63f6-4d73-ba29-94992d854f7f" />
