#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]
set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/"

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
fi

# 1. Проверка наличия главной страницы
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "deploy: файл site/index.html не найден" >&2
    exit 1
fi

# 2. Проверка незафиксированных изменений (включая индекс)
if [[ -n "$(git status --porcelain)" ]]; then
    echo "deploy: в репозитории есть незафиксированные изменения:" >&2
    git status --short >&2
    exit 1
fi

# 3. Синхронизация. Одно SSH-соединение на запуск
RSYNC_SSH="ssh -o BatchMode=yes -o ConnectTimeout=5"
RSYNC_OPTS=(-az --delete --chmod=D755,F644 -e "${RSYNC_SSH}")
if (( DRY_RUN )); then
    RSYNC_OPTS+=(--dry-run)
fi
rsync "${RSYNC_OPTS[@]}" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

if (( DRY_RUN )); then
    echo "deploy: план операций проверен, изменения не вносились"
    exit 0
fi

# 4. Проверка доступности с проверкой сертификата (без -k)
if ! curl -fsS --cacert "${CA_CERT}" -o /dev/null "${SITE_URL}/"; then
    echo "deploy: ресурс ${SITE_URL} недоступен" >&2
    exit 1
fi

echo "deploy: ресурс ${SITE_URL} доступен"
echo "доставлен коммит $(git rev-parse --short HEAD)"
