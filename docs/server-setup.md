# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- Гипервизор: VirtualBox 7.x, ОС: Ubuntu Server 24.04 LTS (64-bit)
- Оперативная память: 2048 МБ
- Процессор: 2 ядра
- Диск: 25 ГБ, динамически расширяемый
- Имя узла: devops-vm (FQDN: devops-vm.devops.local)

## 2. Сетевые интерфейсы
| Адаптер | Тип | Адрес | Назначение |
|---|---|---|---|
| 1 | NAT | 10.0.2.15 | доступ гостя в Интернет (apt), проброс порта |
| 2 | Host-only | 192.168.56.101 | доступ с хоста: SSH, веб-сервер (работа № 6) |

## 3. Правило проброса портов
- Имя: ssh, протокол TCP
- Адрес хоста: 127.0.0.1, порт хоста: 2222
- Адрес гостя: не задан, порт гостя: 2222 (изначально 22, изменён после смены порта SSH)

## 4. Учётные записи
| Пользователь | Группы | Аутентификация |
|---|---|---|
| student | student, sudo | пароль (только консоль ВМ), по SSH вход запрещён |
| devops | devops, sudo | только по ключу ed25519 (~/.ssh/devops_vm на хосте) |
| root | root | вход по SSH запрещён |

Открытый ключ хранится в /home/devops/.ssh/authorized_keys (права 600, каталог ~/.ssh 700).
На хосте настроен ~/.ssh/config с записью `Host devops` (IdentitiesOnly yes).

## 5. Служба SSH
- Файл конфигурации: /etc/ssh/sshd_config.d/99-hardening.conf
- Резервная копия оригинала: /etc/ssh/sshd_config.backup
- Директивы:
  - Port 2222
  - PermitRootLogin no
  - PasswordAuthentication no
  - PubkeyAuthentication yes
  - PermitEmptyPasswords no
  - MaxAuthTries 3
  - LoginGraceTime 30
  - AllowUsers devops
  - X11Forwarding no
  - ClientAliveInterval 300
  - ClientAliveCountMax 2
- Конфликтующая строка PasswordAuthentication yes в 50-cloud-init.conf закомментирована.
- Активация по сокету отключена: `systemctl disable --now ssh.socket`, `systemctl enable --now ssh.service`.
- Проверка: `sudo sshd -t`, действующие значения: `sudo sshd -T`.

## 6. Правила межсетевого экрана
- Политики: default deny incoming, default allow outgoing, логирование medium
- Правила (UFW):
  - 2222/tcp LIMIT (SSH rate-limited)
  - 80/tcp ALLOW (HTTP, для работы № 6)
  - 443/tcp ALLOW (HTTPS)
- Порядок: сначала правила allow/limit для 2222, затем `ufw enable`.

## 7. Снимки состояния
| Наименование | Момент создания |
|---|---|
| 01-clean-install | после установки ОС, apt upgrade, выключения командой poweroff |
| 02-keys-configured | после настройки ключевой аутентификации и ~/.ssh/config |
| 03-ssh-hardened | после усиления защиты SSH, смены порта и проверки с отдельного терминала |
| 04-nginx-https | после настройки Nginx, HTTPS и самоподписанного сертификата (работа № 6) |
| 05-docker-compose | после запуска проекта Docker Compose (работа № 7) |

## 8. Веб-сервер

- Устанавливаемый пакет: nginx 1.24.0-2ubuntu7.2 (apt).
- Конфигурация ресурса: /etc/nginx/sites-available/devops-site, включена
  символической ссылкой в /etc/nginx/sites-enabled/; файл
  /etc/nginx/sites-enabled/default удалён.
- Каталог ресурса: /var/www/devops-site, владелец devops:devops,
  права каталогов 755, файлов 644.
- Сертификат: /etc/ssl/certs/devops.crt, владелец root:root, права 644,
  CN=devops.local, SAN DNS:devops.local, срок действия 365 дней.
- Ключ: /etc/ssl/private/devops.key, владелец root:root, права 600.
- Формирование сертификата:
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/devops.key \
    -out /etc/ssl/certs/devops.crt \
    -subj "/CN=devops.local" \
    -addext "subjectAltName=DNS:devops.local"
- Применение конфигурации: sudo nginx -t && sudo systemctl reload nginx.
- Проверка: curl --cacert ~/devops.crt -I https://devops.local.

## 9. Контейнеризация

- Docker Engine 28.5.1 установлен из официального репозитория Docker
  (пакет docker-ce), плагин Docker Compose v2.40.3.
- Группа docker: участник devops (учётная запись с правом sudo).
- Проект: /home/devops/app, доставляется rsync из каталога app/
  репозитория с исключением .env.
- Файл .env: /home/devops/app/.env, владелец devops:devops, права 600;
  в репозитории отсутствует, шаблон - app/.env.example.
- Порты: 127.0.0.1:5000 -> 5000/tcp (приложение); порт 5432 не публикуется.
- Именованный том: app_db_data, каталог /var/lib/postgresql/data, СУБД
  postgres:16-alpine.
- Сеть проекта: app_backend (bridge), сервис db разрешается по имени db.
- Обратный прокси-сервер: location /app/ в
  /etc/nginx/sites-available/devops-site,
  proxy_pass http://127.0.0.1:5000/.
- Запуск: docker compose up -d; остановка: docker compose stop app.
- Восстановление: cd ~/app && cp .env.example .env &&
  chmod 600 .env, затем docker compose up -d --build.
