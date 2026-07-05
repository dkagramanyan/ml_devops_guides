# Reverse proxy на Raspberry Pi с wildcard-сертификатом Let's Encrypt

Руководство по настройке домена в Selectel, выпуску wildcard-сертификата, обратного прокси Traefik и разрешению имён внутри локальной сети через MikroTik. Docker-часть опущена.

## Итоговая схема

Запрос проходит два этапа:

1. **DNS** направляет клиента на IP-адрес Raspberry Pi.
2. **Traefik** на Pi читает заголовок `Host` и проксирует запрос на нужный сервис по порту.

```
клиент → DNS (MikroTik/Selectel) → IP Raspberry Pi → Traefik → нужный сервис
```

Один wildcard-сертификат `*.dgkagramanyan.ru` закрывает все поддомены. Новые сервисы не требуют ни нового сертификата, ни изменений в Selectel.

## 1. DNS-записи в Selectel

Зона `dgkagramanyan.ru` находится на актуальном (v2) DNS-хостинге Selectel.

Создайте группы записей типа A:

| Имя группы | Тип | Значение | TTL |
|---|---|---|---|
| `dgkagramanyan.ru.` | A | публичный IP | 3600 |
| `www.dgkagramanyan.ru.` | A | публичный IP | 3600 |
| `*.dgkagramanyan.ru.` | A | публичный IP | 3600 |

Запись `*` покрывает все поддомены сразу. Отдельные записи (`www`, апекс) имеют приоритет над wildcard для своих имён.

Проверка распространения:

```bash
dig +short jupyterlab.dgkagramanyan.ru @1.1.1.1
```

## 2. Wildcard-сертификат: два пути

### Путь A. Панель Selectel (ручное продление)

Certificate Manager → Добавить сертификат → Let's Encrypt. В основном домене укажите `dgkagramanyan.ru`, в дополнительном домене введите `*` перед фиксированным суффиксом, чтобы получилось `*.dgkagramanyan.ru`. Проверка домена (DNS-01) выполняется автоматически, так как зона у Selectel.

Минус: Selectel продлевает свою копию, но не передаёт её на Pi. Каждые 90 дней файлы нужно скачивать и заменять вручную.

### Путь B. Traefik выпускает сам (авто-продление, рекомендуется)

Traefik запрашивает и продлевает wildcard сам через DNS-01 challenge Selectel. Ручные действия не нужны никогда. Ниже настроен именно этот путь.

## 3. Сервисный пользователь Selectel для API

Актуальный DNS API v2 авторизуется через сервисного пользователя OpenStack, а не через статический токен.

1. Панель → **Управление доступом (IAM)** → **Сервисные пользователи** → создать, задать пароль.
2. Назначить пользователю роль на **проекте**, где лежит DNS-зона: область **Проект**, роль **Администратор проекта** (или `member`). Без роли авторизация возвращает `Authentication failed`.
3. Собрать четыре значения:

| Переменная | Что это | Где взять |
|---|---|---|
| `SELECTELV2_USERNAME` | имя сервисного пользователя | IAM → Сервисные пользователи |
| `SELECTELV2_PASSWORD` | его пароль | задаётся при создании |
| `SELECTELV2_ACCOUNT_ID` | номер аккаунта, целое число | правый верхний угол панели |
| `SELECTELV2_PROJECT_ID` | ID проекта, hex-UUID | Проекты → нужный проект → ID |

Частая ошибка: в `PROJECT_ID` подставляют имя проекта вместо UUID.

Проверка учётных данных напрямую (минуя Traefik). HTTP 201 — всё верно, 401 — неверный пароль или нет роли на проекте, 400/404 — неверный account/project ID:

```bash
USERNAME='...'; PASSWORD='...'; ACCOUNT='...'; PROJECT='...'
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  -X POST 'https://cloud.api.selcloud.ru/identity/v3/auth/tokens' \
  -H 'Content-Type: application/json' \
  -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"'"$USERNAME"'","domain":{"name":"'"$ACCOUNT"'"},"password":"'"$PASSWORD"'"}}},"scope":{"project":{"id":"'"$PROJECT"'","domain":{"name":"'"$ACCOUNT"'"}}}}}'
```

## 4. Файл окружения `.env`

Спецсимволы в пароле (`$`, `#`, пробелы) заключайте в одинарные кавычки.

```env
DOMAIN=dgkagramanyan.ru

SELECTELV2_USERNAME=dns-acme
SELECTELV2_PASSWORD='пароль'
SELECTELV2_ACCOUNT_ID=312045
SELECTELV2_PROJECT_ID=7f3e9a1c8b6d4f20a5c1e8d9b2f04a6c
```

## 5. Статическая конфигурация Traefik `traefik.yml`

Меняется редко, изменения требуют пересоздания контейнера.

```yaml
api:
  dashboard: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false
  file:
    directory: /etc/traefik/dynamic
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@dgkagramanyan.ru
      storage: /letsencrypt/acme.json
      # На время отладки раскомментируйте staging, чтобы не тратить лимит:
      # caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      dnsChallenge:
        provider: selectelv2
        propagation:
          delayBeforeChecks: 20s
        # Проверять записи на самих NS Selectel, а не на публичных резолверах,
        # иначе проверка распространения зависает.
        resolvers:
          - "a.ns.selectel.ru:53"
          - "b.ns.selectel.ru:53"

log:
  level: INFO
accessLog: {}
```

## 6. Динамическая маршрутизация `dynamic/native-services.yml`

Описывает маршруты к сервисам. Файл **перечитывается на лету** (`watch: true`), перезапуск не нужен. Один роутер и один сервис на каждое имя.

```yaml
http:
  routers:
    kuma:
      rule: "Host(`kuma.dgkagramanyan.ru`)"
      entryPoints:
        - websecure
      service: kuma
      tls: {}          # использует уже выпущенный wildcard

    jupyterlab:
      rule: "Host(`jupyterlab.dgkagramanyan.ru`)"
      entryPoints:
        - websecure
      service: jupyterlab
      tls: {}

  services:
    kuma:
      loadBalancer:
        servers:
          - url: "http://raspberrypi:3001"      # сервис на самом Pi

    jupyterlab:
      loadBalancer:
        servers:
          - url: "http://192.168.88.50:8888"    # сервис на другой машине LAN
```

Адрес бэкенда задаётся в `url`. Это не редирект: Traefik терминирует TLS на себе и проксирует запрос на бэкенд по обычному HTTP. Браузер остаётся на `https://имя.dgkagramanyan.ru`.

**Когда нужен перезапуск, а когда нет:**

- Правки в `dynamic/*.yml` — подхватываются сами, перезапуск не нужен.
- Правки в `traefik.yml` — нужен пересоздать контейнер.

## 7. Выпуск сертификата: staging → production

Let's Encrypt ограничивает число неудачных попыток (5 на домен в час). Сначала отлаживайте на staging.

1. В `traefik.yml` раскомментировать строку `caServer` (staging), пересоздать контейнер.
2. Дождаться `The server validated our request` для обоих доменов и `Server responded with a certificate`. Сертификат staging браузер не доверяет — это нормально.
3. Закомментировать `caServer` обратно (production), очистить хранилище и пересоздать:

```bash
rm letsencrypt/acme.json && touch letsencrypt/acme.json && chmod 600 letsencrypt/acme.json
```

4. В логе должно появиться `acmeCA=https://acme-v02.api.letsencrypt.org/directory` (без `staging`) и снова `Server responded with a certificate`.

Признак успеха в логе:

```
INF The server validated our request. domain=*.dgkagramanyan.ru
INF Server responded with a certificate.
```

Проверить, какой сертификат реально отдаётся:

```bash
echo | openssl s_client -connect raspberrypi:443 -servername kuma.dgkagramanyan.ru 2>/dev/null \
  | openssl x509 -noout -issuer
```

Издатель с `R10/R11/E5/E6` — боевой доверенный сертификат. С `STAGING`/`Fake LE` — ещё staging.

Если после выпуска браузер показывает предупреждение — это кеш staging. Жёсткое обновление (Ctrl+Shift+R) или режим инкогнито.

## 8. Разрешение имён внутри LAN (split-DNS на MikroTik)

Публичный DNS указывает на публичный IP. Чтобы клиенты в локальной сети шли напрямую на Pi, а не через интернет, MikroTik должен переопределять эти имена на локальный IP Pi.

Регулярное выражение в кавычках, точка как `[.]`, конец строки как `\$`:

```
/ip dns static
add regexp="[.]dgkagramanyan[.]ru\$" address=192.168.88.X
```

`192.168.88.X` — локальный IP Raspberry Pi (узнать: `ip -4 addr show`). Одна запись покрывает все поддомены.

Для голого апекса без поддомена добавить обычную запись:

```
/ip dns static
add name=dgkagramanyan.ru address=192.168.88.X
```

Условия работы:

- `/ip dns print` показывает `allow-remote-requests: yes`.
- Клиенты LAN используют MikroTik как DNS-сервер. Если они смотрят напрямую в AdGuard или Cloudflare, переопределение делается там.

Проверка и сброс кеша:

```
/ip dns cache flush
```

```bash
nslookup jupyterlab.dgkagramanyan.ru   # должен вернуть локальный IP Pi
```

## 9. Публикация сервиса в интернет

Весь внешний трафик идёт через Traefik на портах 80/443. Порт на каждый сервис открывать не нужно.

### Проброс портов на MikroTik

```
/ip firewall nat
add chain=dstnat action=dst-nat protocol=tcp dst-port=80 \
  in-interface-list=WAN to-addresses=192.168.88.X to-ports=80 \
  comment="HTTP to Traefik"
add chain=dstnat action=dst-nat protocol=tcp dst-port=443 \
  in-interface-list=WAN to-addresses=192.168.88.X to-ports=443 \
  comment="HTTPS to Traefik"
```

Если в цепочке forward стоит финальный `drop`, разрешить трафик до Pi:

```
/ip firewall filter
add chain=forward action=accept protocol=tcp dst-port=80,443 \
  dst-address=192.168.88.X comment="Allow WAN to Traefik"
```

### Публичный DNS

Поддомены, которые должны быть доступны снаружи, должны резолвиться в **публичный WAN-IP** дома. Узнать реальный IP: `curl ifconfig.me`. При необходимости обновить wildcard-запись в Selectel.

### Ограничение доступа к чувствительным сервисам

Wildcard делает публично резолвимыми все поддомены. Админки (AdGuard, дашборд Traefik, JupyterLab) наружу выставлять не стоит. Ограничить их middleware по IP, оставив порт открытым только для LAN:

```yaml
http:
  middlewares:
    lan-only:
      ipAllowList:
        sourceRange:
          - "192.168.88.0/24"
          - "127.0.0.1/32"
  routers:
    adguard:
      rule: "Host(`adguard.dgkagramanyan.ru`)"
      entryPoints: [websecure]
      service: adguard
      tls: {}
      middlewares: [lan-only]   # интернет получит 403
```

Публичные сервисы просто не подключают этот middleware.

### Обязательный минимум по безопасности

- На всех сервисах без собственной авторизации включить логин или middleware `lan-only`.
- Дашборд Traefik никогда не делать публичным (basic-auth или `lan-only`).
- Split-DNS оставляет клиентов LAN на прямом пути к Pi, hairpin NAT не задействуется.
- Держать Pi в актуальном состоянии, рассмотреть fail2ban и rate-limiting.

## Добавление нового сервиса: краткий чеклист

1. Имя уже покрыто wildcard-сертификатом и regex MikroTik — Selectel трогать не нужно.
2. Добавить пару router + service в `dynamic/native-services.yml`, указать `url` бэкенда.
3. Сохранить файл — Traefik подхватит сам.
4. При необходимости закрыть сервис middleware `lan-only`.
5. Открыть `https://имя.dgkagramanyan.ru`.

## Типичные проблемы

| Симптом | Причина и решение |
|---|---|
| `selectelv2: Authentication failed` | Нет роли на проекте или `PROJECT_ID` = имя вместо UUID. Проверить curl-тестом (раздел 3). |
| `waiting for record propagation` зависает | Публичные резолверы отстают. Указать `a.ns.selectel.ru:53` в `resolvers`. |
| `too many failed authorizations (5)` | Лимит Let's Encrypt. Перейти на staging, дождаться сброса лимита. |
| Браузер: «не защищено» после выпуска | Ещё staging-сертификат либо кеш. Проверить издателя через openssl, обновить страницу жёстко. |
| `client version 1.24 is too old` | Старый Traefik с Docker 29+. Обновить образ Traefik до v3.7+. |
