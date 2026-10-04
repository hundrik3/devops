# Самостоятельная загрузка на GitHub

Архив содержит только исходники, документацию и результаты проверок. Локальный пароль Jenkins, kubeconfig, Maven cache и Docker-инструменты исключены.

Распакуйте архив. Из каталога `devops` можно загрузить проект в свой пустой репозиторий:

```bash
git init -b main
git add .
git status --short
# Проверьте, что среди файлов нет .env, .local и kubeconfig.
git commit -m "Add Java delivery lab with Jenkins, Docker and Kubernetes"
git remote add origin https://github.com/hundrik3/devops.git
git push -u origin main
```

Эти команды рассчитаны на распакованный архив без `.git`. В существующей локальной копии репозитория повторно добавлять `origin` не нужно. Если удалённый репозиторий уже содержит коммиты, сначала получите их и согласуйте историю; не используйте force push.

Для демонстрации запустите стенд по README и сделайте собственные скриншоты успешной сборки Jenkins, двух pod и страницы приложения. Текст для портфолио находится в `docs/portfolio.md`, результаты проверки — в `docs/validation.md`.

После публикации настройте параметр `SOURCE_REPOSITORY` в Jenkins на свой URL. Основной репозиторий проекта: https://github.com/hundrik3/devops. Эти команды также можно использовать для публикации распакованного архива в другом своём репозитории.
