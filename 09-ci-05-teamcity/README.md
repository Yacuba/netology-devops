# Домашнее задание к занятию 11 «Teamcity»

---

## Подготовка к выполнению

### 1. Создание инстанса TeamCity Server
В Yandex Cloud на базе Container Optimized Image с Docker-образом `jetbrains/teamcity-server:latest` был создан инстанс с конфигурацией 4 vCPU, 4 ГБ RAM.

### 2. Первоначальная настройка TeamCity
После запуска сервера TeamCity на порту `8111` была выполнена первичная инициализация со встроенной базой данных (HSQLDB) и создана учетная запись администратора.

![Image](task_prep_2_screenshot_1)

### 3. Создание инстанса TeamCity Agent
Был создан инстанс с конфигурацией 2 vCPU, 4 ГБ RAM на базе образа `jetbrains/teamcity-agent:latest`. В параметры контейнера передана переменная окружения:
`SERVER_URL: "http://158.160.236.126:8111"`.

### 4. Авторизация агента
В веб-интерфейсе TeamCity в разделе `Agents` -> `Unauthorized` подключившийся агент был авторизован и перешел в статус `Idle`.

![Image](task_prep_4_screenshot_1)

### 5. Fork репозитория
Был сделан fork репозитория [example-teamcity](https://github.com/aragastmatb/example-teamcity) в личный профиль GitHub.

![Image](task_prep_5_screenshot_1)

### 6. Развертывание Nexus с помощью Ansible Playbook
В Yandex Cloud была создана виртуальная машина `nexus-01` на базе CentOS 7 (2 vCPU, 4 ГБ RAM).

Общий список созданных виртуальных машин в Yandex Cloud:
![Image](task_prep_vms_list_screenshot)

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
![Image](task_prep_6_screenshot_1)

Веб-интерфейс развернутого сервиса Nexus (`http://130.193.44.27:8081`):
![Image](task_prep_6_screenshot_2)

---

## Основная часть

### 1. Создание нового проекта в TeamCity на основе fork
В веб-интерфейсе TeamCity был создан новый проект на основе URL форка репозитория: `https://github.com/Yacuba/example-teamcity.git`.

![Image](task_main_1_screenshot_1)

### 2. Autodetect конфигурации
TeamCity автоматически проанализировал репозиторий и определил шаг сборки Maven с целями `clean test` и файлом дескриптора `pom.xml`.

![Image](task_main_2_screenshot_1)

### 3. Сохранение шагов и первый запуск сборки master
Автоматически определенный шаг сборки Maven (`clean test`) был сохранен в конфигурации. Запущена первая сборка ветки `master` (Build #1), завершившаяся со статусом Success (5 пройденных тестов).

![Image](task_main_3_screenshot_1)

### 4. Настройка условий сборки по веткам
Для сборки были настроены два шага runner'а Maven:
1. `Maven Test (non-master)` - выполняет цель `clean test` с условием `teamcity.build.branch does not equal master`.
2. `Maven Deploy (master)` - выполняет цель `clean deploy` с условием `teamcity.build.branch equals master`.

В настройках VCS Root параметр **Branch specification** был дополнен шаблоном `+:refs/heads/*` для отслеживания всех веток репозитория.

![Image](task_main_4_screenshot_1)

### 5. Загрузка settings.xml в конфигурацию Maven
Файл `settings.xml`, содержащий учетные данные для доступа к репозиторию Nexus (`admin` / `admin123` для сервера с id `nexus`), был загружен в настройках проекта TeamCity в раздел **Maven Settings** и привязан к шагу сборки `Maven Deploy (master)` в параметре **User settings selection**.

![Image](task_main_5_screenshot_1)

### 6. Обновление pom.xml
В файле `pom.xml` репозитория `example-teamcity` были обновлены ссылки на URL репозитория проекта и актуальный адрес репозитория развертывания Nexus (`http://130.193.44.27:8081/repository/maven-releases/`):

![Image](task_main_6_screenshot_1)

### 7. Сборка ветки master и публикация артефакта в Nexus
Была запущена сборка по ветке `master`. В соответствии с настроенными условиями:
- Шаг `Maven Test (non-master)` был пропущен (`unfulfilled condition`).
- Шаг `Maven Deploy (master)` успешно выполнил `mvn clean deploy`.

![Image](task_main_7_screenshot_1)

В результате успешного выполнения сборки артефакт `plaindoll-0.0.2.jar` вместе с pom-файлом и контрольными суммами был опубликован в репозитории `maven-releases` сервиса Nexus:

![Image](task_main_7_screenshot_2)

### 8. Миграция конфигурации сборки в репозиторий (Versioned Settings)
В настройках проекта была включена синхронизация параметров сборки с репозиторием GitHub (Versioned Settings) в формате Kotlin DSL. Для записи TeamCity был предоставлен Personal Access Token с правами `repo`.

![Image](task_main_8_screenshot_1)

В результате синхронизации в корне репозитория `example-teamcity` был создан каталог `.teamcity` с кодом конфигурации сборки и проектов:

![Image](task_main_8_screenshot_2)

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

![Image](task_main_9_12_screenshot_1)

### 13. Автоматический запуск сборки по ветке `feature/add_reply`
При поступлении изменений в ветку `feature/add_reply` TeamCity автоматически обнаружил новый коммит через VCS Trigger и запустил сборку (Build #6).
  
- Шаг сборки `Maven Test (non-master)` успешно выполнил `mvn clean test` (пройдено 6 тестов).
- Шаг `Maven Deploy (master)` был пропущен.
- Сборка завершилась со статусом Success.

![Image](task_main_13_screenshot_1)

### 14. Слияние ветки `feature/add_reply` в `master`
Изменения из ветки `feature/add_reply` были объединены с веткой `master` через merge-коммит и отправлены в GitHub. TeamCity автоматически обнаружил обновление ветки `master` и успешно выполнил сборку (Build #7), прогнав 6 тестов и выполнив деплой в Nexus.

![Image](task_main_14_screenshot_1)

### 15. Проверка артефактов сборки
На вкладке **Artifacts** завершенной сборки Build #7 отображается *«No user-defined artifacts in this build»*, так как сохранение jar-файлов в артефакты TeamCity еще не было настроено.

![Image](task_main_15_screenshot_1)

### 16. Настройка сбора артефактов сборки
В разделе **General Settings** конфигурации сборки в параметре **Artifact paths** было задано правило сбора jar-файлов:
```text
target/*.jar
```

![Image](task_main_16_screenshot_1)

### 17. Повторная сборка master и проверка артефактов
Была запущена повторная сборка ветки `master`. Сборка завершилась успешно, а на вкладке **Artifacts** появились сгенерированные файлы пакетов:
- `plaindoll-0.0.2.jar` (3.09 KB)
- `original-plaindoll-0.0.2.jar` (2.89 KB)

![Image](task_main_17_screenshot_1)

### 18. Проверка конфигурации в репозитории
В файле конфигурации `.teamcity/settings.kts` ветки `master` репозитория `example-teamcity` зафиксированы все произведенные настройки, включая правило сбора артефактов `artifactRules = "target/*.jar"`, шаги Maven с условиями выполнения по веткам и VCS-триггер:

![Image](task_main_18_screenshot_1)

### 19. Ссылки на репозитории
1. Репозиторий с проектом (форк с кодом, тестами и конфигурацией TeamCity в `.teamcity`):  
   [https://github.com/Yacuba/example-teamcity](https://github.com/Yacuba/example-teamcity)
2. Файл с отчетом о выполнении домашнего задания:  
   [https://github.com/Yacuba/netology-devops/blob/09-ci-05-teamcity/09-ci-05-teamcity/README.md](https://github.com/Yacuba/netology-devops/blob/09-ci-05-teamcity/09-ci-05-teamcity/README.md)