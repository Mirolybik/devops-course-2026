# devops-course-2026

Учебный репозиторий по дисциплине «Инструменты DevOps».

## Структура

| Путь | Назначение |
|---|---|
| `docs/server-setup.md` | конфигурация виртуальной машины devops-vm: сеть, SSH, UFW, Nginx, Docker |
| `scripts/audit.sh` | аудит конфигурации: SSH, межсетевой экран, учётные записи, веб-сервер, контейнеры |
| `scripts/deploy.sh` | доставка статического ресурса на сервер средствами rsync |
| `site/` | статический ресурс: главная страница и собственная страница ошибки 404 |
| `nginx/devops-site.conf` | конфигурация ресурса devops.local с обратным прокси для приложения |
| `app/` | Flask-приложение, Dockerfile, `docker-compose.yml` и шаблон переменных окружения |

## Развёртывание

```bash
# статический ресурс
./scripts/deploy.sh --dry-run
./scripts/deploy.sh

# приложение
cd ~/app
cp .env.example .env
chmod 600 .env
docker compose up -d --build
```

Проверка конфигурации и доступности:

```bash
./scripts/audit.sh
curl --cacert ~/devops.crt https://devops.local/
curl --cacert ~/devops.crt https://devops.local/app/health
```
