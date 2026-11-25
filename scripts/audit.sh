#!/usr/bin/env bash
# Аудит конфигурации devops-vm: SSH, межсетевой экран, учётные записи,
# веб-сервер и контейнеры.
set -uo pipefail

PASS=0; FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo "  [OK]   $desc"; ((PASS++))
    else
        echo "  [FAIL] $desc (ожидалось: '$expected', получено: '$actual')"; ((FAIL++))
    fi
}

echo "Аудит конфигурации: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo "[1] Служба SSH"
check "Вход от имени root запрещён"        "no"  "$(sudo sshd -T | awk '/^permitrootlogin/{print $2}')"
check "Парольная аутентификация отключена" "no"  "$(sudo sshd -T | awk '/^passwordauthentication/{print $2}')"

# Порт отличен от 22
port="$(sudo sshd -T | awk '/^port/{print $2}')"
[[ "$port" != "22" ]] && port_state="не 22" || port_state="$port"
check "Порт SSH отличен от 22" "не 22" "$port_state"

# MaxAuthTries равен 3
check "MaxAuthTries равен 3" "3" "$(sudo sshd -T | awk '/^maxauthtries/{print $2}')"

echo "[2] Межсетевой экран"
check "Межсетевой экран активен" "active" "$(sudo ufw status | awk '/^Status:/{print $2}')"

# Политика по умолчанию для входящего трафика - deny
check "Политика входящего трафика: deny" "deny" "$(sudo ufw status verbose | grep Default | awk '{print $2}')"

echo "[3] Учётные записи"
awk -F: '$3>=1000 && $3<65534 {printf "    %s (uid=%s)\n",$1,$3}' /etc/passwd
check "Пользователь devops входит в группу sudo" "yes" \
      "$(id -nG devops | grep -qw sudo && echo yes || echo no)"

echo "[4] Веб-сервер"
check "Служба nginx активна" "active" "$(systemctl is-active nginx)"
check "Конфигурация nginx корректна" \
      "$(sudo nginx -t >/dev/null 2>&1; echo $?)" "0"
check "Сертификат действует не менее 30 дней" \
      "$(openssl x509 -checkend 2592000 -noout \
         -in /etc/ssl/certs/devops.crt >/dev/null 2>&1; echo $?)" "0"
check "Права ключа /etc/ssl/private/devops.key равны 600" \
      "$(sudo stat -c '%a' /etc/ssl/private/devops.key)" "600"
if [[ -z "$(find /var/www/devops-site -perm -o+w -print -quit 2>/dev/null)" ]]; then
    check "В каталоге ресурса нет файлов, доступных для записи всем" "ok" "ok"
else
    echo "  [FAIL] Найдены файлы, доступные для записи всем:"
    find /var/www/devops-site -perm -o+w -print
    ((FAIL++))
fi

echo "[5] Контейнеризация"
check "Служба docker активна" "$(systemctl is-active docker)" "active"
check "Контейнер СУБД находится в состоянии healthy" \
      "$(docker inspect -f '{{.State.Health.Status}}' app-db-1 2>/dev/null)" "healthy"
check "Порты 5000 и 5432 не прослушиваются вне 127.0.0.1" \
      "$(ss -tln | awk '$4 ~ /:(5000|5432)$/ && $4 !~ /^127\.0\.0\.1:/ {print $4}' | wc -l)" "0"
check "Права файла ~/app/.env равны 600" "$(stat -c '%a' ~/app/.env)" "600"

echo "[6] Контрольная работа №2"
check "Контейнер сервиса redis находится в состоянии healthy" \
      "$(docker compose --project-directory ~/kr2 ps -q redis \
         | xargs -r docker inspect -f '{{.State.Health.Status}}')" "healthy"
check "Порт 8001 опубликован только на 127.0.0.1" \
      "$(docker compose --project-directory ~/kr2 port app 8001)" "127.0.0.1:8001"
check "Права файла ~/kr2/.env равны 600" "$(stat -c '%a' ~/kr2/.env)" "600"
check "Сертификат /etc/ssl/certs/kr2.crt действует не менее 30 дней" \
      "$(openssl x509 -checkend 2592000 -noout \
         -in /etc/ssl/certs/kr2.crt >/dev/null 2>&1; echo $?)" "0"
check "Ресурс kr2 активирован" "yes" \
      "$([ -L /etc/nginx/sites-enabled/kr2 ] && echo yes || echo no)"

echo "Пройдено проверок: $PASS, не пройдено: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
