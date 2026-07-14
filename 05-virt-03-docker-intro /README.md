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
   Контейнер был переименован без оставновки и удаления в `custom-nginx-t2`:
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

## Задача 4

## Задача 5
