# Reverse proxy на Raspberry Pi: Traefik + wildcard Let's Encrypt

Traefik на Pi проксирует поддомены `*.dgkagramanyan.ru` к сервисам в LAN, сам выпускает и продлевает wildcard-сертификат через Selectel DNS-01, плюс мониторинг Prometheus + Grafana.

```
клиент → DNS (MikroTik/Selectel) → Pi:443 (Traefik) → бэкенд по Host-заголовку
```

Файлы стека: `docker-compose.yml`, `traefik.yml`, `.env`, `prometheus.yml`, `dynamic/native-services.yml`, `certs/`, `letsencrypt/`.

---

## 1. DNS в Selectel

Зона `dgkagramanyan.ru` на DNS-хостинге v2. Записи A:

| Имя | Тип | Значение |
|---|---|---|
| `dgkagramanyan.ru.` | A | публичный IP |
| `*.dgkagramanyan.ru.` | A | публичный IP |

`*` покрывает все поддомены. Проверка: `dig +short kuma.dgkagramanyan.ru @1.1.1.1`.

---

## 2. Сервисный пользователь Selectel (API v2)

DNS API v2 авторизуется через сервисного пользователя OpenStack.

1. Панель → **IAM → Сервисные пользователи** → создать, задать пароль.
2. Назначить роль **member** (или Администратор проекта) на **проекте** с DNS-зоной. Без роли → `Authentication failed`.
3. Собрать: `USERNAME`, `PASSWORD`, `ACCOUNT_ID` (целое, справа вверху панели), `PROJECT_ID` (hex-UUID, не имя проекта).

Проверка кредов (201 = ок, 401 = пароль/роль, 400/404 = account/project ID):

```bash
USERNAME='...'; PASSWORD='...'; ACCOUNT='...'; PROJECT='...'
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  -X POST 'https://cloud.api.selcloud.ru/identity/v3/auth/tokens' \
  -H 'Content-Type: application/json' \
  -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"'"$USERNAME"'","domain":{"name":"'"$ACCOUNT"'"},"password":"'"$PASSWORD"'"}}},"scope":{"project":{"id":"'"$PROJECT"'","domain":{"name":"'"$ACCOUNT"'"}}}}}'
```

---

## 3. `.env`

Пароль со спецсимволами — в одинарных кавычках.

```env
DOMAIN=dgkagramanyan.ru
SELECTELV2_USERNAME=dns-acme
SELECTELV2_PASSWORD='пароль'
SELECTELV2_ACCOUNT_ID=312045
SELECTELV2_PROJECT_ID=7f3e9a1c8b6d4f20a5c1e8d9b2f04a6c
# htpasswd -nbB admin 'пароль' | sed -e 's/\$/\$\$/g'
DASHBOARD_AUTH=admin:...
```

---

## 4. `traefik.yml` (статика — при правках пересоздать контейнер)

```yaml
api:
  dashboard: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint: { to: websecure, scheme: https }
  websecure:
    address: ":443"
  metrics:
    address: ":8082"

providers:
  docker:
    exposedByDefault: false
    network: proxy
  file:
    directory: /etc/traefik/dynamic
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@dgkagramanyan.ru
      storage: /letsencrypt/acme.json
      # отладка: caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      dnsChallenge:
        provider: selectelv2
        propagation:
          delayBeforeChecks: 20s
        resolvers:               # NS Selectel, иначе проверка зависает
          - "a.ns.selectel.ru:53"
          - "b.ns.selectel.ru:53"

metrics:
  prometheus:
    entryPoint: metrics
    addRoutersLabels: true

log:
  level: INFO
accessLog: {}
```

---

## 5. Провайдеры маршрутов

- **docker** — метки на контейнерах. Так объявлен `dashboard`, он же запрашивает wildcard-сертификат (метки `tls.domains`).
- **file** — `dynamic/*.yml`, все остальные сервисы. Файлы перечитываются на лету.

В дашборде провайдер виден в имени роутера: `kuma@file`, `dashboard@docker`.

Пересоздание нужно только при правках `traefik.yml` / `docker-compose.yml`. Правки `dynamic/*.yml` — на лету.

---

## 6. `dynamic/native-services.yml`

Один роутер + один сервис на имя. Бэкенд:
- HTTP: `url: "http://host:port"`
- HTTPS с самоподписанным серт.: `url: "https://host:port"` + `serversTransport: insecure-backend`

```yaml
http:
  routers:
    kuma:
      rule: "Host(`kuma.dgkagramanyan.ru`)"
      entryPoints: [websecure]
      service: kuma
      tls: {}
    proxmox:
      rule: "Host(`proxmox.dgkagramanyan.ru`)"
      entryPoints: [websecure]
      service: proxmox
      tls: {}
    grafana:
      rule: "Host(`grafana.dgkagramanyan.ru`)"
      entryPoints: [websecure]
      service: grafana
      tls: {}

  services:
    kuma:
      loadBalancer:
        servers: [{ url: "http://raspberrypi:3001" }]
    proxmox:
      loadBalancer:
        serversTransport: insecure-backend
        servers: [{ url: "https://acserver:8006" }]
    grafana:
      loadBalancer:
        servers: [{ url: "http://grafana:3000" }]

  serversTransports:
    insecure-backend:
      insecureSkipVerify: true
```

Бэкенд-контейнер стека адресуется по имени (`http://grafana:3000`), должен быть в сети `proxy`. Нерезолвящиеся имена (`homepc`, `acserver`, `openwrt`) добавить в `extra_hosts` контейнера traefik.

---

## 7. Выпуск сертификата: staging → production

Let's Encrypt: 5 неудачных попыток на домен в час. Сначала staging.

1. Раскомментировать `caServer` (staging), пересоздать контейнер.
2. Дождаться `Server responded with a certificate`. Staging браузер не доверяет — норма.
3. Вернуть production (закомментировать `caServer`), очистить хранилище, пересоздать:

```bash
rm letsencrypt/acme.json && touch letsencrypt/acme.json && chmod 600 letsencrypt/acme.json
docker compose up -d --force-recreate
```

4. В логе `acmeCA=https://acme-v02...` (без `staging`).

Проверка выданного серт.:

```bash
echo | openssl s_client -connect raspberrypi:443 -servername kuma.dgkagramanyan.ru 2>/dev/null | openssl x509 -noout -issuer
```

`R10/R11/E5/E6` — боевой. `STAGING`/`Fake LE` — ещё staging. Предупреждение после выпуска — кеш, обновить Ctrl+Shift+R.

---

## 8. Split-DNS на MikroTik (LAN идёт напрямую на Pi)

```
/ip dns static
add regexp="[.]dgkagramanyan[.]ru\$" address=192.168.88.X
add name=dgkagramanyan.ru address=192.168.88.X
/ip dns cache flush
```

`192.168.88.X` — LAN-IP Pi. Условия: `/ip dns print` → `allow-remote-requests: yes`; клиенты используют MikroTik как DNS.

---

## 9. Внешний доступ

Проброс на MikroTik (только 80/443 → Pi, Traefik разведёт по Host):

```
/ip firewall nat
add chain=dstnat action=dst-nat protocol=tcp dst-port=80 in-interface-list=WAN to-addresses=192.168.88.X to-ports=80
add chain=dstnat action=dst-nat protocol=tcp dst-port=443 in-interface-list=WAN to-addresses=192.168.88.X to-ports=443
```

Публичный DNS поддомена → WAN-IP (`curl ifconfig.me`).

**Ограничение админок по IP** (Proxmox, LuCI, Omada, OpenVPN, дашборд, Grafana):

```yaml
http:
  middlewares:
    lan-only:
      ipAllowList:
        sourceRange: ["192.168.88.0/24", "127.0.0.1/32"]
  routers:
    proxmox:
      rule: "Host(`proxmox.dgkagramanyan.ru`)"
      entryPoints: [websecure]
      service: proxmox
      tls: {}
      middlewares: [lan-only]   # интернет → 403
```

---

## 10. Сторонний домен через Traefik (wiki.aripari.am)

Домен не из wildcard, поэтому сертификат отдельный. Бэкенд `170.134.51.33:443` уже отдаёт валидный LE-сертификат.

**Маршрут** (`native-services.yml`): бэкенд адресуется по IP, поэтому `insecure-backend`.

```yaml
  routers:
    wiki-aripari:
      rule: "Host(`wiki.aripari.am`)"
      entryPoints: [websecure]
      service: wiki-aripari
      tls: {}
  services:
    wiki-aripari:
      loadBalancer:
        serversTransport: insecure-backend
        servers: [{ url: "https://170.134.51.33:443" }]
```

**Сертификат** — скопировать с бэкенда и подключить файлом:

```bash
mkdir -p ~/traefik/certs
ssh sysadmin@170.134.51.33 'sudo cp /etc/letsencrypt/live/wiki.aripari.am/{fullchain.pem,privkey.pem} /tmp/ && sudo chown sysadmin /tmp/fullchain.pem /tmp/privkey.pem'
scp sysadmin@170.134.51.33:/tmp/fullchain.pem ~/traefik/certs/wiki.aripari.am.crt
scp sysadmin@170.134.51.33:/tmp/privkey.pem   ~/traefik/certs/wiki.aripari.am.key
chmod 600 ~/traefik/certs/wiki.aripari.am.key
```

`docker-compose.yml` (том): `- ./certs:/certs:ro`. `dynamic/certs.yml`:

```yaml
tls:
  certificates:
    - certFile: /certs/wiki.aripari.am.crt
      keyFile: /certs/wiki.aripari.am.key
```

Split-DNS для LAN: `add name=wiki.aripari.am address=192.168.88.X`. Публичный DNS + проброс :443 → Pi для внешнего доступа.

Скопированный серт. **не продлевается сам** — истекает через ~90 дней. Автоматизировать renewal-hook'ом на бэкенде, копирующим файлы на Pi.

---

## 11. Мониторинг: Prometheus + Grafana

Метрики Traefik уже включены (`:8082`). Ключевая: `traefik_router_requests_total{router,code}`.

### `prometheus.yml`

Должен быть **файлом**. Если Docker создал каталог — `rm -rf prometheus.yml`, создать заново.

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: traefik
    static_configs:
      - targets: ["traefik:8082"]

  # node_exporter на сервере wiki
  - job_name: wiki-host
    static_configs:
      - targets: ["170.134.51.33:9100"]
        labels: { instance: wiki }
```

### Контейнеры (в сети `proxy`)

```yaml
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    networks: [proxy]

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=смените
      - GF_SERVER_ROOT_URL=https://grafana.dgkagramanyan.ru   # иначе share-ссылки идут на localhost:3000
      - GF_FEATURE_TOGGLES_ENABLE=publicDashboards
      - GF_CACHING_ENABLED=false                              # иначе public-ссылка отдаёт устаревшие данные
    volumes:
      - grafana-data:/var/lib/grafana
    networks: [proxy]

# volumes:
#   prometheus-data:
#   grafana-data:
```

### node_exporter на сервере wiki (`170.134.51.33`)

```yaml
services:
  node_exporter:
    image: quay.io/prometheus/node-exporter:latest
    container_name: node_exporter
    restart: unless-stopped
    network_mode: host
    pid: host
    command: ['--path.rootfs=/host']
    volumes: ['/:/host:ro,rslave']
```

Порт 9100 закрыть от интернета, открыть только для IP Pi (`ufw allow from <PI_IP> to any port 9100`).

### Дашборд

1. `https://grafana.dgkagramanyan.ru`, вход `admin` / пароль.
2. Data source → Prometheus → `http://prometheus:9090`.
3. Import: Traefik v3 — ID **17346**; Node Exporter Full — ID **1860**.

PromQL:

```promql
sum by (router) (rate(traefik_router_requests_total[1m]))                # req/s на сервис
sum by (router) (rate(traefik_router_requests_total{code=~"5.."}[1m]))   # ошибки 5xx
```

### Публичный дашборд (ссылка без входа)

Share → Public dashboard → Enable.

Важно:
- `GF_SERVER_ROOT_URL` и `GF_FEATURE_TOGGLES_ENABLE=publicDashboards` — обязательны.
- `GF_CACHING_ENABLED=false` — иначе анонимный просмотр отдаёт устаревшие/случайные данные.
- Дашборды с template-переменными (`$job`/`$instance`, как 1860) на public-ссылке пусты. Либо зафиксировать переменную (Settings → Variables → Current value + Hide) на единственный instance, либо использовать дашборд без переменных с жёстко прописанным `job`.
- Публичный дашборд раскрывает внутренние метрики — публиковать только безопасное подмножество.

---

## Чеклист нового сервиса

1. Имя уже покрыто wildcard-серт. и regex MikroTik — Selectel не трогать.
2. Router + service в `native-services.yml`, указать `url`.
3. HTTPS-бэкенд с самоподписанным серт. → `serversTransport: insecure-backend`.
4. Сохранить — подхватится само.
5. Админку закрыть `lan-only`.

---

## Типичные проблемы

| Симптом | Решение |
|---|---|
| `selectelv2: Authentication failed` | Нет роли на проекте или `PROJECT_ID` = имя. Curl-тест (разд. 2). |
| `waiting for record propagation` виснет | Указать `a.ns.selectel.ru:53` в `resolvers`. |
| `too many failed authorizations (5)` | Лимит LE. Перейти на staging. |
| «не защищено» после выпуска | Staging-серт. или кеш. Проверить `openssl`, Ctrl+Shift+R. |
| `client version 1.24 is too old` | Docker 29+ со старым Traefik. Образ `traefik:v3.7`. |
| `tls: failed to verify certificate: valid for X` | HTTPS-бэкенд по IP/самоподпись. `serversTransport: insecure-backend`. |
| `504` на проксируемый бэкенд | Pi не достаёт бэкенд по указанному IP. `nc -zv host 443`, поправить `url`. |
| `not a directory: mount prometheus.yml` | Docker создал каталог. `rm -rf prometheus.yml`, создать файлом. |
| `mapping values are not allowed` | Отступы YAML. `serversTransport` и `servers` на одном уровне в `loadBalancer`. |
| Grafana public: «No data» / случайные графики | `GF_CACHING_ENABLED=false`; зафиксировать template-переменные или дашборд без них. |
| Grafana share-ссылка на `localhost:3000` | Задать `GF_SERVER_ROOT_URL`. |
