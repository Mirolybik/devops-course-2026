# Контрольная работа №2: приложение + Redis в Docker, публикация по HTTPS

Вариант 1: доменное имя `api.devops.local`, порт приложения `8001`, ветка `kr2/variant-1`.

## Состав

| Файл | Назначение |
|---|---|
| `app/app.py` | Flask-приложение: счётчик обращений в Redis, `/health`, `/whoami` |
| `app/Dockerfile` | образ `kr2-app:1.0` на базе `python:3.12-slim`, процесс от пользователя `app` |
| `app/docker-compose.yml` | сервисы `app` и `redis`, сеть `backend`, том `redis_data`, проверка готовности |
| `app/.env.example` | шаблон переменных: без действующего пароля |
| `app/.dockerignore` | исключает `.env` и `.git` из контекста сборки |
| `scripts/audit.sh` | раздел `[6] Контрольная работа №2` |

## Запуск на сервере

```bash
rsync -avz --delete --exclude=.env --exclude=.git ./app/ devops:kr2/
ssh devops
cd ~/kr2
cp .env.example .env
sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=$(openssl rand -hex 32)/" .env
chmod 600 .env
docker compose up -d --build
curl -s http://127.0.0.1:8001/health
```

Порт `8001` публикуется только на `127.0.0.1` и доступен снаружи через Nginx:
HTTP перенаправляется на HTTPS кодом 301, сертификат `/etc/ssl/certs/kr2.crt`
содержит `subjectAltName=DNS:api.devops.local`.

## Проверка

```bash
curl --cacert ~/kr2.crt https://api.devops.local/
curl --cacert ~/kr2.crt https://api.devops.local/whoami
(cd ~/devops-course-2026 && scripts/audit.sh); echo $?
```

Ожидаемый результат: счётчик растёт, `/whoami` показывает `scheme: https`,
аудит завершается кодом `0` и сообщением `Пройдено проверок: 21, не пройдено: 0`.
