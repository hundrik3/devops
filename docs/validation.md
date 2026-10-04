# Проверка локального стенда

Дата: 4 октября 2026. Проверки выполнены в Linux x86_64 с Docker Engine 28.4.0 (storage driver vfs).

| Проверка | Результат | Подтверждение |
|---|---|---|
| Сборка Maven и упаковка WAR | PASS | Jenkins builds #6, #8, #9 |
| JUnit | 4 tests, 0 failures, 0 errors, 0 skipped | evidence/junit.xml |
| Docker build и локальный импорт containerd | PASS | evidence/jenkins-console.txt |
| Kubernetes rollout | PASS, 2 доступные реплики | evidence/deployment.txt, evidence/pods.txt |
| HTTP smoke | Все 6 проверок прошли | evidence/jenkins-console.txt |
| Запрос через настоящий ClusterIP Service из Kind-ноды | Hello, Service! | evidence/service-response.txt |
| Повторная доставка | PASS | Успешные builds #6 и #8 |
| Архивирование WAR и JUnit XML | PASS | Итог Finished: SUCCESS; WAR проверен в Jenkins archive |
| Пропуск неизменных исходников | PASS, build #7; тесты и rollout не выполнялись | evidence/unchanged-console.txt |
| Rollback #8 → образ #6 и HTTP smoke | PASS | evidence/rollback.txt |
| Восстановление образа #8 после rollback | PASS | evidence/rollback.txt |
| Перезапуск Jenkins и Kubernetes | PASS; затем полная успешная сборка #9 | evidence/restart.txt, evidence/jenkins-build.json |
| Повторный bootstrap без пересборки Jenkins | PASS | evidence/repeated-bootstrap.txt |
| Авторизация Jenkins | Задание доступно с авторизацией, анонимный доступ закрыт | scripts/check-jenkins.py выполнен успешно |
| Kubernetes server-side dry-run и Pod Security policy | PASS | deployment, service, namespace приняты API server |
| Bash/Python syntax и Compose config | PASS | Проверены локальными командами |

Версии: Jenkins 2.541.3 / JDK 21, Maven 3.9.9, приложение с Java release 17 на Tomcat 10.1.34 / JDK 17, Kind 0.27.0, Kubernetes/kubectl 1.32.2. Docker-образы закреплены digest, CLI-файлы проверены SHA-256.

## Исправленные проблемы настройки

- Вложенная Docker-среда не поддерживала IPv6 iptables и overlayfs внутри Kind. Использована сеть IPv4 и native snapshotter.
- Для containerd 2 импорт через transfer API не поддерживал выбранный snapshotter. Использован локальный `ctr images import --local --snapshotter=native`.
- Отсутствующий kernel log device восстановлен внутри собственной Kind-ноды.
- Maven настроен на существующий HTTPS proxy и доверенные CA, без отключения TLS verification.
- Исправлены права чтения init-скрипта и выполнения CLI в контейнере Jenkins.
- При первых сборках vfs занял диск: функциональные проверки проходили, но архивирование завершалось ошибкой. Удалены только промежуточные артефакты настройки, Dockerfile сокращён до одного слоя приложения, повторная сборка Jenkins зависит от хеша входов и ID образа, неизменный здоровый Deployment не пересобирается. Итоговые builds #6, #8 и #9 полностью успешны.

## Не выполнялось

AWS EC2, push образа в registry, GitHub webhook, удалённый GitHub-режим после пользовательской публикации, security scan, нагрузочный тест и непрерывное измерение доступности при rolling update. Скриншоты не создавались; их можно сделать на своём стенде по docs/portfolio.md.

Это доказательства текущего локального запуска. Новая облачная задача после публикации snapshot отдельно не проверялась. Конфигурация install_script и start_skill сохранена в черновик среды; публикация облачной среды отдельно не проверялась. Проверки приложения относятся к локальному стенду, а не к GitHub-hosted инфраструктуре.
