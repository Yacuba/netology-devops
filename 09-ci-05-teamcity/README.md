# Домашнее задание к занятию 11 «Teamcity»

---

## Подготовка к выполнению

### 1. Создание инстанса TeamCity Server
В Yandex Cloud на базе Container Optimized Image с Docker-образом `jetbrains/teamcity-server:latest` был создан инстанс с конфигурацией 4 vCPU, 4 ГБ RAM.

### 2. Первоначальная настройка TeamCity
После запуска сервера TeamCity на порту `8111` была выполнена первичная инициализация со встроенной базой данных (HSQLDB) и создана учетная запись администратора.

<img width="556" height="516" alt="Снимок экрана 2026-09-26 143800" src="https://github.com/user-attachments/assets/8fe677a1-e0b3-4a2e-ac5c-9b0b23bc5838" />

### 3. Создание инстанса TeamCity Agent
Был создан инстанс с конфигурацией 2 vCPU, 4 ГБ RAM на базе образа `jetbrains/teamcity-agent:latest`. В параметры контейнера передана переменная окружения:
`SERVER_URL: "http://158.160.236.126:8111"`.

### 4. Авторизация агента
В веб-интерфейсе TeamCity в разделе `Agents` -> `Unauthorized` подключившийся агент был авторизован и перешел в статус `Idle`.

<img width="281" height="199" alt="Снимок экрана 2026-09-26 144545" src="https://github.com/user-attachments/assets/d055b32f-8d48-4121-86ab-ced5a1d0eb94" />

### 5. Fork репозитория
Был сделан fork репозитория [example-teamcity](https://github.com/aragastmatb/example-teamcity) в личный профиль GitHub.  

<img width="472" height="209" alt="Снимок экрана 2026-09-26 144759" src="https://github.com/user-attachments/assets/575a247f-996d-4767-8f2d-8ac65bbc0824" />

### 6. Развертывание Nexus с помощью Ansible Playbook
В Yandex Cloud была создана виртуальная машина `nexus-01` на базе CentOS 7 (2 vCPU, 4 ГБ RAM).

Общий список созданных виртуальных машин в Yandex Cloud:  
<img width="814" height="194" alt="Снимок экрана 2026-09-26 150838" src="https://github.com/user-attachments/assets/7ca17620-ccae-4464-a39e-82e3fcd2fef6" />

В файле `infrastructure/inventory/cicd/hosts.yml` был настроен инвентарь:
```yaml
---
all:
  hosts:
    nexus-01:
      ansible_host: 130.193.44.27
  children:
    nexus:
      hosts:
        nexus-01:
  vars:
    ansible_connection: ssh
    ansible_user: yachi
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    ansible_python_interpreter: /usr/bin/python3
```

В файле `infrastructure/site.yml` в таске `Download Nexus` были добавлены параметры `validate_certs: false` и `timeout: 120`.

Запуск плейбука:
```bash
ansible-playbook -i inventory/cicd/hosts.yml site.yml
```

Результат выполнения плейбука:  
<img width="813" height="100" alt="Снимок экрана 2026-09-26 152450" src="https://github.com/user-attachments/assets/75adf2aa-cedb-47de-a498-bfdd56a7d93a" />

Веб-интерфейс развернутого сервиса Nexus (`http://130.193.44.27:8081`):  
<img width="1101" height="381" alt="Снимок экрана 2026-09-26 152531" src="https://github.com/user-attachments/assets/b7017373-5083-4cba-97b0-c6c5fb5f3ac9" />

---

## Основная часть

### 1. Создание нового проекта в TeamCity на основе fork
В веб-интерфейсе TeamCity был создан новый проект на основе URL форка репозитория: `https://github.com/Yacuba/example-teamcity.git`.

<img width="678" height="628" alt="Снимок экрана 2026-09-26 174929" src="https://github.com/user-attachments/assets/504b26fd-085b-453b-ae05-151de9249dd9" />

### 2. Autodetect конфигурации
TeamCity автоматически проанализировал репозиторий и определил шаг сборки Maven с целями `clean test` и файлом дескриптора `pom.xml`.

<img width="661" height="231" alt="Снимок экрана 2026-09-26 175042" src="https://github.com/user-attachments/assets/2057def3-db35-402c-a8ed-ed41c49d9fdc" />

### 3. Сохранение шагов и первый запуск сборки master
Автоматически определенный шаг сборки Maven (`clean test`) был сохранен в конфигурации. Запущена первая сборка ветки `master` (Build #1), завершившаяся со статусом Success (5 пройденных тестов).

<img width="749" height="284" alt="Снимок экрана 2026-09-26 180516" src="https://github.com/user-attachments/assets/772f10b7-3799-4763-b9d1-09a77aca586e" />

### 4. Настройка условий сборки по веткам
Для сборки были настроены два шага runner'а Maven:
1. `Maven Test (non-master)` - выполняет цель `clean test` с условием `teamcity.build.branch does not equal master`.
2. `Maven Deploy (master)` - выполняет цель `clean deploy` с условием `teamcity.build.branch equals master`.

В настройках VCS Root параметр **Branch specification** был дополнен шаблоном `+:refs/heads/*` для отслеживания всех веток репозитория.

<img width="790" height="445" alt="Снимок экрана 2026-09-26 182704" src="https://github.com/user-attachments/assets/e5021242-affa-4da8-94f1-a7cf29d15741" />

### 5. Загрузка settings.xml в конфигурацию Maven
Файл `settings.xml`, содержащий учетные данные для доступа к репозиторию Nexus (`admin` / `admin123` для сервера с id `nexus`), был загружен в настройках проекта TeamCity в раздел **Maven Settings** и привязан к шагу сборки `Maven Deploy (master)` в параметре **User settings selection**.

<img width="842" height="125" alt="Снимок экрана 2026-09-26 183330" src="https://github.com/user-attachments/assets/1299013a-6fcf-4ca4-8702-43405dfc85bb" />

### 6. Обновление pom.xml
В файле `pom.xml` репозитория `example-teamcity` были обновлены ссылки на URL репозитория проекта и актуальный адрес репозитория развертывания Nexus (`http://130.193.44.27:8081/repository/maven-releases/`):

<img width="628" height="421" alt="Снимок экрана 2026-09-26 184409" src="https://github.com/user-attachments/assets/e95e9668-127c-4243-9e1b-d21ed24affef" />

### 7. Сборка ветки master и публикация артефакта в Nexus
Была запущена сборка по ветке `master`. В соответствии с настроенными условиями:
- Шаг `Maven Test (non-master)` был пропущен (`unfulfilled condition`).
- Шаг `Maven Deploy (master)` успешно выполнил `mvn clean deploy`.

<img width="1406" height="759" alt="Снимок экрана 2026-09-26 185046" src="https://github.com/user-attachments/assets/10d36ec0-1e83-4ae1-bf0b-943827bc8918" />

В результате успешного выполнения сборки артефакт `plaindoll-0.0.2.jar` вместе с pom-файлом и контрольными суммами был опубликован в репозитории `maven-releases` сервиса Nexus:

<img width="323" height="402" alt="Снимок экрана 2026-09-26 185139" src="https://github.com/user-attachments/assets/3dc378c8-f03a-478a-9c91-93927888fdf2" />

### 8. Миграция конфигурации сборки в репозиторий (Versioned Settings)
В настройках проекта была включена синхронизация параметров сборки с репозиторием GitHub (Versioned Settings) в формате Kotlin DSL. Для записи TeamCity был предоставлен Personal Access Token с правами `repo`.

<img width="670" height="300" alt="Снимок экрана 2026-09-26 190641" src="https://github.com/user-attachments/assets/6cbb3294-c03e-492f-91fe-7c9ce568e7cc" />

В результате синхронизации в корне репозитория `example-teamcity` был создан каталог `.teamcity` с кодом конфигурации сборки и проектов:

<img width="905" height="376" alt="Снимок экрана 2026-09-26 190742" src="https://github.com/user-attachments/assets/e6acd52a-6905-4484-8a19-bdf27d758c20" />

### 9–12. Разработка новой функциональности в ветке `feature/add_reply`
1. Была создана отдельная ветка `feature/add_reply`.
2. В класс `src/main/java/plaindoll/Welcomer.java` добавлен новый метод `sayHunter()`:
```java
public String sayHunter() {
    return "A hunter must hunt.";
}
```
3. В класс тестов `src/test/java/plaindoll/WelcomerTest.java` добавлен unit-тест `welcomerSaysHunter()`, проверяющий наличие ключевого слова `hunter`:
```java
@Test
public void welcomerSaysSayHunter() {
    assertThat(welcomer.sayHunter(), containsString("hunter"));
}
```
4. Изменения зафиксированы коммитом и отправлены в удаленный репозиторий в ветку `feature/add_reply`.

<img width="904" height="384" alt="Снимок экрана 2026-09-26 191624" src="https://github.com/user-attachments/assets/e6fb848f-5233-41c9-ae41-29eaa8703c65" />

### 13. Автоматический запуск сборки по ветке `feature/add_reply`
При поступлении изменений в ветку `feature/add_reply` TeamCity автоматически обнаружил новый коммит через VCS Trigger и запустил сборку (Build #6).
  
- Шаг сборки `Maven Test (non-master)` успешно выполнил `mvn clean test` (пройдено 6 тестов).
- Шаг `Maven Deploy (master)` был пропущен.
- Сборка завершилась со статусом Success.

<img width="1495" height="587" alt="Снимок экрана 2026-09-26 194158" src="https://github.com/user-attachments/assets/190dbd02-8abf-4f59-9db8-ca5ee8e5c210" />

### 14. Слияние ветки `feature/add_reply` в `master`
Изменения из ветки `feature/add_reply` были объединены с веткой `master` через merge-коммит и отправлены в GitHub. TeamCity автоматически обнаружил обновление ветки `master` и успешно выполнил сборку (Build #7), прогнав 6 тестов и выполнив деплой в Nexus.

<img width="1491" height="488" alt="Снимок экрана 2026-09-26 194641" src="https://github.com/user-attachments/assets/8418aaa6-a444-4fd6-81b7-c8cef77b52c9" />

### 15. Проверка артефактов сборки
На вкладке **Artifacts** завершенной сборки Build #7 отображается *«No user-defined artifacts in this build»*, так как сохранение jar-файлов в артефакты TeamCity еще не было настроено.

<img width="474" height="124" alt="Снимок экрана 2026-09-26 194702" src="https://github.com/user-attachments/assets/4145937d-ec1f-45b5-90ed-e7211faf1e94" />

### 16. Настройка сбора артефактов сборки
В разделе **General Settings** конфигурации сборки в параметре **Artifact paths** было задано правило сбора jar-файлов:
```text
target/*.jar
```

<img width="860" height="189" alt="Снимок экрана 2026-09-26 195026" src="https://github.com/user-attachments/assets/b0597394-987e-4f8e-aa31-944e885659b0" />

### 17. Повторная сборка master и проверка артефактов
Была запущена повторная сборка ветки `master`. Сборка завершилась успешно, а на вкладке **Artifacts** появились сгенерированные файлы пакетов:
- `plaindoll-0.0.2.jar` (3.09 KB)
- `original-plaindoll-0.0.2.jar` (2.89 KB)

<img width="487" height="167" alt="Снимок экрана 2026-09-26 195046" src="https://github.com/user-attachments/assets/98fd671c-4ef3-4f52-b506-07abb3ea7660" />

### 18. Проверка конфигурации в репозитории
В файле конфигурации `.teamcity/settings.kts` ветки `master` репозитория `example-teamcity` зафиксированы все произведенные настройки, включая правило сбора артефактов `artifactRules = "target/*.jar"`, шаги Maven с условиями выполнения по веткам и VCS-триггер:

<img width="396" height="262" alt="Снимок экрана 2026-09-26 195824" src="https://github.com/user-attachments/assets/2812da57-31a4-4b18-b5a2-0426857e2f9a" />

### 19. Ссылки на репозитории
1. Репозиторий с проектом (форк с кодом, тестами и конфигурацией TeamCity в `.teamcity`):  
   [https://github.com/Yacuba/example-teamcity](https://github.com/Yacuba/example-teamcity)
2. Файл с отчетом о выполнении домашнего задания:  
   [https://github.com/Yacuba/netology-devops/blob/09-ci-05-teamcity/09-ci-05-teamcity/README.md](https://github.com/Yacuba/netology-devops/blob/09-ci-05-teamcity/09-ci-05-teamcity/README.md)
