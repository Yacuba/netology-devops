# Домашнее задание 2. Применение принципов IaaC в работе с виртуальными машинами

## Задача 1 и Задача 2
- Успешно установлены VirtualBox, Vagrant, Packer и Yandex Cloud CLI.
- Настроена авторизация в Yandex Cloud через сервисный аккаунт с помощью авторизованного ключа JSON.
- Локальная ВМ успешно запущена в VirtualBox (подтверждено vboxmanage list runningvms), но из-за медленной вложенной виртуализации подключение по SSH завершилось по таймауту.
<img width="791" height="40" alt="image" src="https://github.com/user-attachments/assets/4c51f2eb-bfad-41d1-810c-8f28d3b0a50a" />

## Задача 3
- Отредактирован файл `mydebian.json.pkr.hcl`. Настроена безопасная авторизация через `service_account_key_file` без использования OAuth-токенов в коде.
- В секцию provisioner добавлен скрипт установки Docker, htop и tmux.
- С помощью Packer успешно собран кастомный образ `debian-11-docker` в Yandex Cloud.
- Из созданного образа развернута виртуальная машина в облаке.
- Выполнено подключение по SSH и проверена корректность установки всех утилит.

### Скриншот проверки установленного ПО:
<img width="969" height="590" alt="task3_verification" src="https://github.com/user-attachments/assets/c638d623-b532-4db0-a5f0-5531f0eee868" />
