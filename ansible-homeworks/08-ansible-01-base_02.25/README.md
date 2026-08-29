# Домашнее задание к занятию 1 «Введение в Ansible»

## Подготовка к выполнению

1. Проверка версии Ansible:
```bash
ansible --version
```
<img width="796" height="171" alt="Снимок экрана 2026-08-29 170036" src="https://github.com/user-attachments/assets/b5fc16b8-69a6-459d-b1e2-2410c70f277a" />

---

## Основная часть

### Задание 1

Запуск playbook на окружении `test.yml`:
```bash
ansible-playbook site.yml -i inventory/test.yml
```
<img width="816" height="327" alt="Снимок экрана 2026-08-29 170102" src="https://github.com/user-attachments/assets/ae3a1498-e85b-4253-8aea-619d6dbbdf96" />

**Результат:**
Значение факта `some_fact` для хоста `localhost` равно `12`. Значение берется из файла общих переменных `group_vars/all/examp.yml`.

### Задание 2

Изменено значение переменной `some_fact` в файле `group_vars/all/examp.yml` на `all default fact`.

Проверка применения нового значения запуском playbook:
```bash
ansible-playbook site.yml -i inventory/test.yml
```
<img width="810" height="331" alt="Снимок экрана 2026-08-29 171131" src="https://github.com/user-attachments/assets/4ee1ce80-5b1c-4b44-acec-42884153fcda" />

**Результат:**
Значение факта `some_fact` для хоста `localhost` успешно обновилось и выводится как `all default fact`.

### Задание 3

Подготовка окружения Docker для хостов `prod.yml`:
```bash
docker run -d --name ubuntu pycontribs/ubuntu:latest sleep 1d
docker run -d --name centos7 pycontribs/centos:7 sleep 1d
docker ps
```
<img width="801" height="68" alt="Снимок экрана 2026-08-29 171826" src="https://github.com/user-attachments/assets/e121a430-3789-4c91-b531-03ff3c6cd0fe" />

**Результат:**
Контейнеры `ubuntu` и `centos7` успешно запущены и готовы к подключению по транспорту `docker`.

### Задание 4

Запуск playbook на окружении `prod.yml`:
```bash
ansible-playbook site.yml -i inventory/prod.yml
```
<img width="809" height="468" alt="Снимок экрана 2026-08-29 172347" src="https://github.com/user-attachments/assets/d8eeee2f-9798-49c7-8133-ea63fea21ef2" />

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
<img width="1320" height="327" alt="Снимок экрана 2026-08-29 190319" src="https://github.com/user-attachments/assets/b12743f9-77b8-4cd1-9faf-a635037d6548" />

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
<img width="572" height="273" alt="Снимок экрана 2026-08-29 173801" src="https://github.com/user-attachments/assets/2f2a194a-2833-4462-ae0e-ed78eb9fba2d" />

### Задание 8

Запуск playbook с флагом `--ask-vault-pass`:
```bash
ansible-playbook site.yml -i inventory/prod.yml --ask-vault-pass
```
<img width="813" height="481" alt="Снимок экрана 2026-08-29 173820" src="https://github.com/user-attachments/assets/337e5708-8220-40db-9f58-82c9dc10f0e7" />

**Результат:**
Ansible запросил пароль хранилища, расшифровал переменные на лету и успешно выполнил задачи плейбука.

### Задание 9

Поиск плагина подключения для работы на `control node`:
```bash
ansible-doc -t connection -l | grep -w "local"
```
<img width="416" height="53" alt="Снимок экрана 2026-08-29 180137" src="https://github.com/user-attachments/assets/c1b5dfec-82a6-490b-a33b-fe5b72c11b77" />

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
<img width="828" height="620" alt="Снимок экрана 2026-08-29 180556" src="https://github.com/user-attachments/assets/7478b1ba-f1f1-492a-b35d-ecc38d41dfbe" />

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
<img width="559" height="136" alt="Снимок экрана 2026-08-29 181439" src="https://github.com/user-attachments/assets/bce2ce94-7cd8-46dc-b0b3-f9049d81bfae" />

### Задание 2

Шифрование отдельного значения `PaSSw0rd` для переменной `some_fact` с паролем `netology`:
```bash
ansible-vault encrypt_string 'PaSSw0rd' --name 'some_fact'
```
<img width="639" height="138" alt="Снимок экрана 2026-08-29 181903" src="https://github.com/user-attachments/assets/6f8040d5-9b96-456f-a674-234b855a4853" />

Полученный зашифрованный блок помещен в файл `group_vars/all/examp.yml`.

### Задание 3

Запуск playbook для проверки применения зашифрованного значения `PaSSw0rd`:
```bash
ansible-playbook site.yml -i inventory/prod.yml --ask-vault-pass
```
<img width="811" height="620" alt="Снимок экрана 2026-08-29 182009" src="https://github.com/user-attachments/assets/085ede15-c068-4480-b576-304246a745d0" />

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
<img width="814" height="772" alt="Снимок экрана 2026-08-29 182956" src="https://github.com/user-attachments/assets/826b62f4-f6e6-469e-a6aa-d7d72750080f" />

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
<img width="817" height="194" alt="Снимок экрана 2026-08-29 185558" src="https://github.com/user-attachments/assets/0497b6c8-083f-4720-a038-36700b3188fa" />

**Результат:**
Скрипт автоматически развернул окружение из трёх контейнеров, передал пароль в Ansible Vault, выполнил плейбук на всех 4 целевых хостах и корректно очистил ресурсы.
