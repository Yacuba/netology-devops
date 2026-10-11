# Домашнее задание к занятию 14 «Средство визуализации Grafana»

## Задание 1

Стек мониторинга состоит из трех сервисов: Prometheus, Node Exporter и Grafana. Сервисы объединены в общую сеть Docker bridge.

Конфигурационный файл сборщика метрик `prometheus/prometheus.yml`:
Манифест развертывания `docker-compose.yml`:

Запуск сервисов выполнен командой:

```bash
docker compose up -d
```

После запуска выполнен вход в веб-интерфейс Grafana (`http://localhost:3000`). В разделе Data Sources подключен запущенный Prometheus с сетевым адресом `http://prometheus:9090`. Тест соединения прошел успешно.

<img width="759" height="515" alt="task_1_screenshot_1" src="https://github.com/user-attachments/assets/0b3bfbd7-774f-476a-8e94-58bff3a35d8c" />

## Задание 2

Для мониторинга хоста создан дашборд с четырьмя панелями. Вывод метрик настроен с помощью следующих PromQL-запросов:

1. **Утилизация CPU (в процентах, 100 - idle):**
   ```promql
   100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)
   ```
   В панели задана единица измерения `Percent (0-100)` с фиксированным диапазоном от 0 до 100.

2. **CPULA 1/5/15 (CPU Load Average):**
   - Запрос A (1 минута):
     ```promql
     node_load1
     ```
   - Запрос B (5 минут):
     ```promql
     node_load5
     ```
   - Запрос C (15 минут):
     ```promql
     node_load15
     ```

3. **Количество свободной оперативной памяти:**
   ```promql
   node_memory_MemAvailable_bytes
   ```
   В настройках панели выставлена единица измерения `Data (IEC) -> bytes`, отображающая реальный объем доступной памяти с учетом кэша ОС.

4. **Количество места на файловой системе:**
   ```promql
   node_filesystem_avail_bytes{mountpoint="/"}`
   ```
   Запрос возвращает объем свободного дискового пространства на корневом разделе хоста. Единица измерения задана в `Data (IEC) -> bytes`.

Общий вид получившегося дашборда:

<img width="1190" height="602" alt="task_2_screenshot_1" src="https://github.com/user-attachments/assets/41d88107-a76e-43e4-a1a3-3be31377b780" />

## Задание 3

В рамках задания настроен канал нотификации Telegram:
1. Создан телеграм-бот и получен токен доступа через `@BotFather`.
2. В разделе **Alerting -> Contact points** добавлен контакт `Telegram` с указанием токена бота и Chat ID.
3. В **Alerting -> Notification policies** контакт `Telegram` задан получателем по умолчанию (Default policy).
4. Проведена отправка тестового события из интерфейса Grafana.

<img width="494" height="309" alt="task_3_screenshot_1" src="https://github.com/user-attachments/assets/323fa2ec-56c4-4e92-9470-be60abf7bdfe" />

Для панели `CPU Utilization` настроено правило алерта `High CPU Load`:
- Условие срабатывания: загрузка процессора выше 80% (`IS ABOVE 80`).
- Интервал проверки: каждые 60 секунд.
- Период удержания состояния: 1 минута.

Работоспособность проверена нагрузкой на процессор хоста. При росте утилизации выше 80% статус панели перешел в `Firing`, на графике отобразились точки фиксации порога, а бот прислал уведомление о проблеме. После завершения нагрузки и падения утилизации бот отправил статус `Resolved`.

Итоговый дашборд с активным правилом алерта и сработавшим триггером:

<img width="1204" height="615" alt="task_3_screenshot_2" src="https://github.com/user-attachments/assets/12fc304f-5344-4b43-a455-a0afdb68b2fe" />

Уведомления о срабатывании (Firing) и восстановлении (Resolved) в Telegram:

<img width="481" height="655" alt="task_3_screenshot_3" src="https://github.com/user-attachments/assets/3c7dac7e-6dd0-4602-bc68-00788ca4035d" />

## Задание 4

Модель созданного дашборда экспортирована из настроек Grafana (раздел JSON Model). Итоговый файл сохранен в репозитории проекта:

- Ссылка на JSON-модель: [dashboard.json](./dashboard.json)
