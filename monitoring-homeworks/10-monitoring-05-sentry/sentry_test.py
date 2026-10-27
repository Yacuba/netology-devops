import os
import sentry_sdk

# получение DSN из переменной окружения
SENTRY_DSN = os.getenv("SENTRY_DSN", "https://PUBLIC_KEY@o000000.ingest.sentry.io/0000000")

sentry_sdk.init(
    dsn=SENTRY_DSN,
    environment="development",
    release="devops-homework@1.0.0",
    traces_sample_rate=1.0,
)

# передача глобальных метаданных (пользователь и теги)
sentry_sdk.set_user({"id": "user-42", "email": "devops@example.com", "username": "devops_student"})
sentry_sdk.set_tag("module", "payment-service")

# событие 1 - информационное сообщение
sentry_sdk.capture_message("Запуск тестового сценария мониторинга", level="info")

# событие 2 - перехваченная ошибка с контекстом
try:
    config = {"db_host": "127.0.0.1"}
    db_port = config["db_port"]
except KeyError as err:
    sentry_sdk.set_context("database_params", {"retry_count": 3, "timeout": 30})
    sentry_sdk.capture_exception(err)

# событие 3 - деление на 0
try:
    total_amount = 1000
    subscribers = 0
    per_user = total_amount / subscribers
except ZeroDivisionError as err:
    sentry_sdk.capture_exception(err)

print("Все тестовые события отправлены в Sentry!")