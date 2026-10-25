# Домашнее задание к занятию 15 «Система сбора логов Elastic Stack»

## Задание 1

Развернут стек сбора логов версии 8.7.0. Все сервисы объединены в общую сеть `elastic` и запущены в изолированных контейнерах.

Конфигурационные файлы размещены в репозитории:
- [docker-compose.yml](./docker-compose.yml) - манифест развертывания пяти компонентов стека;
- [configs/logstash.conf](./configs/logstash.conf) - конфигурация конвейера Logstash;
- [configs/filebeat.yml](./configs/filebeat.yml) - конфигурация агента сбора логов Filebeat.

### Ключевые решения по конфигурации

- **Elasticsearch (hot и warm):** нода `es-hot` настроена с ролями `master,data_content,data_hot`, а нода `es-warm` - с ролями `master,data_warm`. Взаимное обнаружение узлов задано через `discovery.seed_hosts` и `cluster.initial_master_nodes`. Безопасность `xpack.security` отключена для локального контура.
- **Logstash:** конвейер содержит два сетевых входа. Порт `5046` принимает сырые JSON-сообщения по TCP согласно ТЗ (`codec => json`), а порт `5044` выделен под протокол Beats для приема логов контейнеров.
- **Filebeat:** агент читает файлы логов из каталога `/var/lib/docker/containers/*/*.log`, обогащает события метаданными через смонтированный сокет `docker.sock` и отправляет их в Logstash на порт `5044`.

### Результаты проверки

Все пять контейнеров успешно стартовали и работают стабильно:

<img width="1368" height="223" alt="task_1_screenshot_1" src="https://github.com/user-attachments/assets/98b6a4b5-67ea-4051-90c7-c8d9da362c09" />

Интерфейс Kibana доступен в браузере по адресу `http://localhost:5601`:

<img width="582" height="711" alt="task_1_screenshot_2" src="https://github.com/user-attachments/assets/6d81616c-c42a-4d71-8324-30e978779418" />

## Задание 2

Для генерации тестового потока данных в манифест `docker-compose.yml` добавлен сервис `some_app`. Приложение непрерывно отправляет в stdout структурированные JSON-сообщения с разными уровнями важности (`INFO`, `WARNING`, `ERROR`). Агент Filebeat перехватывает вывод контейнера и пересылает события через Logstash в Elasticsearch. 

### Создание Data Views (Index Patterns)

В разделе Kibana **Stack Management -> Data Views** созданы три представления данных под разные сценарии выборки:
- `logstash-all` (шаблон `logstash-*`) - агрегирует все суточные и архивные индексы;
- `logstash-today` (шаблон `logstash-2026.10.25`) - изолирует события за текущий день;
- `logstash-archive` (шаблон `logstash-2026.10.11`) - охватывает архивные логи предыдущих контейнеров системы.

Список созданных Data Views:

<img width="685" height="421" alt="task_2_screenshot_1" src="https://github.com/user-attachments/assets/2032974a-dc5e-4ea4-9336-06ba82769c26" />

### Просмотр и фильтрация логов в Kibana Discover

В разделе **Analytics -> Discover** выбран Data View `logstash-today`. Поток логов от `some_app` отображается на временной гистограмме.

Для проверки работы поисковых запросов применен KQL-фильтр по уровню сообщений:
```text
level : "ERROR"
```

Все сообщения были распарсены - поля JSON (`level`, `message`, `status_code`) и метаданные контейнера (`container.name`, `agent.version`) доступны для поиска и детального анализа:

<img width="1914" height="939" alt="task_2_screenshot_2" src="https://github.com/user-attachments/assets/6d918b21-e85e-4b9c-a03e-3e2207223e0c" />
