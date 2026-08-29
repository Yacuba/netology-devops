# Домашнее задание к занятию 1 «Введение в Ansible»

## Подготовка к выполнению

1. Проверка версии Ansible:
```bash
ansible --version
```
![Версия Ansible](task_0_screenshot_1)

---

## Основная часть

### Задание 1

Запуск playbook на окружении `test.yml`:
```bash
ansible-playbook site.yml -i inventory/test.yml
```
![Запуск playbook на тестовом окружении test.yml](task_1_screenshot_1)

**Результат:**
Значение факта `some_fact` для хоста `localhost` равно `12`. Значение берется из файла общих переменных `group_vars/all/examp.yml`.

### Задание 2

Изменено значение переменной `some_fact` в файле `group_vars/all/examp.yml` на `all default fact`.

Проверка применения нового значения запуском playbook:
```bash
ansible-playbook site.yml -i inventory/test.yml
```
![Проверка изменения переменной all default fact](task_2_screenshot_1)

**Результат:**
Значение факта `some_fact` для хоста `localhost` успешно обновилось и выводится как `all default fact`.

### Задание 3

Подготовка окружения Docker для хостов `prod.yml`:
```bash
docker run -d --name ubuntu pycontribs/ubuntu:latest sleep 1d
docker run -d --name centos7 pycontribs/centos:7 sleep 1d
docker ps
```
![Запущенные Docker-контейнеры для prod.yml](task_3_screenshot_1)

**Результат:**
Контейнеры `ubuntu` и `centos7` успешно запущены и готовы к подключению по транспорту `docker`.

### Задание 4

Запуск playbook на окружении `prod.yml`:
```bash
ansible-playbook site.yml -i inventory/prod.yml
```
![Запуск playbook на окружении prod.yml](task_4_screenshot_1)

**Результат:**
Получены следующие значения переменной `some_fact`:
- Для хоста `centos7` (группа `el`): `"el"` (значение из `group_vars/el/examp.yml`);
- Для хоста `ubuntu` (группа `deb`): `"deb"` (значение из `group_vars/deb/examp.yml`).

### Задания 5 и 6

В файлы переменных групп хостов добавлены новые значения:
- `group_vars/deb/examp.yml` — значение `deb default fact`
- `group_vars/el/examp.yml` — значение `el default fact`

Повторный запуск playbook на окружении `prod.yml`:
```bash
ansible-playbook site.yml -i inventory/prod.yml
```
![Повторный запуск playbook после обновления group_vars](task_6_screenshot_1)

**Результат:**
Для каждого хоста успешно применились специфичные для его группы переменные:
- `centos7`: `"el default fact"`
- `ubuntu`: `"deb default fact"`

### Задание 7

Шифрование файлов переменных с паролем `netology`:
```bash
ansible-vault encrypt group_vars/deb/examp.yml
ansible-vault encrypt group_vars/el/examp.yml
```
![Зашифрованные файлы group_vars](task_7_screenshot_1)

### Задание 8

Запуск playbook с флагом `--ask-vault-pass`:
```bash
ansible-playbook site.yml -i inventory/prod.yml --ask-vault-pass
```
![Запуск с паролем Vault](task_8_screenshot_1)

**Результат:**
Ansible запросил пароль хранилища, расшифровал переменные на лету и успешно выполнил задачи плейбука.

### Задание 9

Поиск плагина подключения для работы на `control node`:
```bash
ansible-doc -t connection -l | grep -w "local"
```
![Плагин подключения local](task_9_screenshot_1)

**Результат:**
Для управления локальным хостом (`control node`) выбран плагин `ansible.builtin.local` (*execute on controller*).

---

### Задания 10 и 11

В файл `inventory/prod.yml` добавлена группа `local`:
```yaml
---
el:
  hosts:
    centos7:
      ansible_connection: docker
deb:
  hosts:
    ubuntu:
      ansible_connection: docker
local:
  hosts:
    localhost:
      ansible_connection: local
```

Запуск playbook на обновлённом окружении `prod.yml`:
```bash
ansible-playbook site.yml -i inventory/prod.yml --ask-vault-pass
```
![Итоговый запуск playbook на окружении prod.yml](task_11_screenshot_1)

**Результат:**
Все факты `some_fact` определены корректно согласно приоритету и иерархии `group_vars`:
- `centos7` (группа `el`): `"el default fact"` (из зашифрованного `group_vars/el/examp.yml`);
- `ubuntu` (группа `deb`): `"deb default fact"` (из зашифрованного `group_vars/deb/examp.yml`);
- `localhost` (группа `local`): `"all default fact"` (из `group_vars/all/examp.yml`, так как для группы `local` отдельный файл переменных не задан).

---

## Необязательная часть

### Задание 1

Расшифровка всех ранее зашифрованных файлов переменных:
```bash
ansible-vault decrypt group_vars/deb/examp.yml group_vars/el/examp.yml
```
![Расшифровка файлов переменных](task_opt_1_screenshot_1)

### Задание 2

Шифрование отдельного значения `PaSSw0rd` для переменной `some_fact` с паролем `netology`:
```bash
ansible-vault encrypt_string 'PaSSw0rd' --name 'some_fact'
```
![Шифрование отдельной строки](task_opt_2_screenshot_1)

Полученный зашифрованный блок помещен в файл `group_vars/all/examp.yml`.

### Задание 3

Запуск playbook для проверки применения зашифрованного значения `PaSSw0rd`:
```bash
ansible-playbook site.yml -i inventory/prod.yml --ask-vault-pass
```
![Запуск playbook со зашифрованной строкой](task_opt_3_screenshot_1)

**Результат:**
- Для `centos7` и `ubuntu` применились значения из их собственных (расшифрованных) файлов переменных (`el default fact` и `deb default fact`);
- Для `localhost` применилось расшифрованное на лету значение `PaSSw0rd` из общего файла `group_vars/all/examp.yml`.

### Задание 4

Добавлена новая группа хостов `fedora`:
1. Запущен Docker-контейнер `fedora` из образа `pycontribs/fedora:latest`.
2. Создан файл `group_vars/fedora/examp.yml` со значением:
   ```yaml
   ---
   some_fact: "fedora default fact"
   ```
3. Группа `fedora` добавлена в `inventory/prod.yml`.

Запуск playbook на обновленном окружении с 4 хостами:
```bash
ansible-playbook site.yml -i inventory/prod.yml --ask-vault-pass
```
![Запуск playbook с группой fedora](task_opt_4_screenshot_1)

**Результат:**
Все 4 хоста успешно обработаны, факт `some_fact` для хоста `fedora` равен `"fedora default fact"`.

### Задание 5

Написан bash-скрипт `run.sh` для полной автоматизации цикла тестирования:
```bash
#!/usr/bin/env bash
set -e

echo "=== Starting Docker containers ==="
# Remove old containers if they already exist
docker rm -f centos7 ubuntu fedora 2>/dev/null || true

docker run -d --name centos7 pycontribs/centos:7 sleep 1d
docker run -d --name ubuntu pycontribs/ubuntu:latest sleep 1d
docker run -d --name fedora pycontribs/fedora:latest sleep 1d

echo "=== Running Ansible Playbook ==="
# Create a temporary Vault password file for non-interactive execution
echo "netology" > .vault_pass
ansible-playbook site.yml -i inventory/prod.yml --vault-password-file .vault_pass
rm -f .vault_pass

echo "=== Stopping and removing Docker containers ==="
docker rm -f centos7 ubuntu fedora

echo "=== Script finished successfully ==="
```

Запуск скрипта:
```bash
./run.sh
```
![Автоматический запуск окружения и playbook скриптом run.sh](task_opt_5_screenshot_1)

**Результат:**
Скрипт автоматически развернул окружение из трёх контейнеров, передал пароль в Ansible Vault, выполнил плейбук на всех 4 целевых хостах и корректно очистил ресурсы.