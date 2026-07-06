# Домашний reverse proxy на Raspberry Pi

Как я поднял Traefik на Raspberry Pi, чтобы все домашние сервисы открывались по красивым адресам вида `kuma.dgkagramanyan.ru` с нормальным HTTPS, а не по `IP:порт` без сертификата. Заодно — мониторинг через Grafana и проксирование стороннего домена. Ниже весь путь с объяснениями, почему всё сделано именно так.

## Как это вообще работает

Идея простая: один вход, много сервисов. Раньше каждый сервис жил на своём порту (`raspberrypi:3001`, `acserver:8006` и т.д.), у каждого — свой самоподписанный сертификат или вообще голый HTTP. Теперь всё заходит через Traefik на 443 порту, а он уже смотрит на заголовок `Host` в запросе и решает, куда переслать.

```
браузер → DNS → Pi:443 (Traefik) → нужный бэкенд, выбранный по имени хоста
```

Запрос на `kuma.dgkagramanyan.ru` и на `proxmox.dgkagramanyan.ru` приходят на один и тот же порт, но Traefik разводит их по разным сервисам. Один wildcard-сертификат `*.dgkagramanyan.ru` закрывает сразу все поддомены, поэтому новый сервис не требует ни нового сертификата, ни возни с DNS — просто дописал маршрут, и готово.

Весь стек живёт в папке на Pi: `docker-compose.yml`, `traefik.yml`, `.env`, папка `dynamic/` с маршрутами, `certs/` и `letsencrypt/` для сертификатов.

## Шаг 1. Домен и DNS в Selectel

Зона `dgkagramanyan.ru` у меня на DNS-хостинге Selectel (актуальная версия, v2). Нужны всего две A-записи:

| Имя | Значение |
|---|---|
| `dgkagramanyan.ru.` | публичный IP |
| `*.dgkagramanyan.ru.` | публичный IP |

Звёздочка — это и есть магия: она ловит вообще любой поддомен. Не надо заводить запись под каждый сервис отдельно. Проверить, что запись разошлась, можно так:

```bash
dig +short kuma.dgkagramanyan.ru @1.1.1.1
```

## Шаг 2. Доступ к Selectel API (самое муторное)

Чтобы Traefik сам выпускал сертификаты, ему нужно доказать Let's Encrypt, что домен наш. Делается это через DNS-01 challenge: Traefik временно создаёт TXT-запись в зоне. А для этого ему нужен доступ к DNS API Selectel.

Тут главная засада: актуальный API Selectel (v2) авторизуется не статическим токеном, а **сервисным пользователем OpenStack**. Если пытаться подсунуть обычный токен — получишь `Authentication failed` и будешь долго гадать почему.

Что нужно сделать в панели:

1. **IAM → Сервисные пользователи** → создать пользователя с паролем.
2. Обязательно **назначить ему роль на проекте**, где лежит DNS-зона (роль `member` или «Администратор проекта»). Это ключевой момент — пользователь без роли авторизуется «в никуда» и даёт ту же ошибку `Authentication failed`.
3. Собрать четыре значения: имя пользователя, пароль, `ACCOUNT_ID` (номер аккаунта — целое число, в правом верхнем углу панели) и `PROJECT_ID` (это hex-UUID проекта, **не его название** — на этом спотыкаются чаще всего).

Прежде чем мучить Traefik, проверить креды напрямую можно вот так. Код 201 — всё в порядке, 401 — не тот пароль или нет роли, 400/404 — перепутан account или project ID:

```bash
USERNAME='...'; PASSWORD='...'; ACCOUNT='...'; PROJECT='...'
curl -s -o /dev/null -w "HTTP %{http_code}\n" \
  -X POST 'https://cloud.api.selcloud.ru/identity/v3/auth/tokens' \
  -H 'Content-Type: application/json' \
  -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"'"$USERNAME"'","domain":{"name":"'"$ACCOUNT"'"},"password":"'"$PASSWORD"'"}}},"scope":{"project":{"id":"'"$PROJECT"'","domain":{"name":"'"$ACCOUNT"'"}}}}}'
```

## Шаг 3. Файл `.env`

Сюда складываем секреты, чтобы не хардкодить их в конфигах. Если в пароле есть спецсимволы (`$`, `#`, пробелы) — оберни его в одинарные кавычки, иначе docker-compose их съест.

```env
DOMAIN=dgkagramanyan.ru
SELECTELV2_USERNAME=dns-acme
SELECTELV2_PASSWORD='пароль'
SELECTELV2_ACCOUNT_ID=312045
SELECTELV2_PROJECT_ID=7f3e9a1c8b6d4f20a5c1e8d9b2f04a6c
DASHBOARD_AUTH=admin:...
```

`DASHBOARD_AUTH` — это логин-пароль для дашборда Traefik. Хеш генерится так (двойные `$$` нужны, чтобы compose не принял `$` за подстановку переменной):

```bash
htpasswd -nbB admin 'пароль' | sed -e 's/\$/\$\$/g'
```

## Шаг 4. Статический конфиг `traefik.yml`

Это «постоянные» настройки Traefik — точки входа, откуда брать маршруты, как выпускать сертификаты. Меняется редко, и при любой правке контейнер надо пересоздавать (не просто перезапускать).

```yaml
api:
  dashboard: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint: { to: websecure, scheme: https }   # весь HTTP гоним на HTTPS
  websecure:
    address: ":443"
  metrics:
    address: ":8082"                                     # для Prometheus, см. мониторинг

providers:
  docker:                    # маршруты из меток на контейнерах
    exposedByDefault: false
    network: proxy
  file:                      # маршруты из файлов dynamic/*.yml
    directory: /etc/traefik/dynamic
    watch: true              # перечитываются на лету

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@dgkagramanyan.ru
      storage: /letsencrypt/acme.json
      # на время отладки — staging, чтобы не выжечь лимит боевого LE:
      # caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      dnsChallenge:
        provider: selectelv2
        propagation:
          delayBeforeChecks: 20s
        resolvers:           # спрашиваем сами NS Selectel — иначе проверка зависает
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

Пара тонкостей, на которые я потратил время:

- **`resolvers` на NS Selectel** — если оставить публичные `1.1.1.1`/`8.8.8.8`, проверка распространения TXT-записи может намертво зависнуть, потому что публичные резолверы не сразу видят свежую запись. Спрашивать сами серверы Selectel надёжнее.
- **staging сначала** — у Let's Encrypt лимит: 5 неудачных попыток на домен в час. Пока настраиваешь и что-то не так с доступом к DNS, легко упереться в лимит и потом час ждать. Поэтому сперва отлаживаемся на staging.

## Шаг 5. Откуда Traefik берёт маршруты

Важно понять, что маршруты приходят из **двух источников одновременно**:

- **docker** — Traefik читает метки (`labels`) прямо с контейнеров. Так у меня объявлен роутер `dashboard`, и он же заодно запрашивает wildcard-сертификат.
- **file** — файлы в `dynamic/`. Тут всё остальное: и внешние сервисы, и контейнеры стека.

В списке роутеров это видно по суффиксу: `kuma@file`, `dashboard@docker`. Полезно помнить: правки в `dynamic/*.yml` подхватываются сами, а вот `traefik.yml` и `docker-compose.yml` требуют пересоздания контейнера.

## Шаг 6. Маршруты сервисов — `dynamic/native-services.yml`

Вот тут описываются сами сервисы: один роутер + один сервис на каждое имя. Роутер говорит «лови такой хост», сервис — «шли вот сюда».

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
        serversTransport: insecure-backend      # бэкенд на HTTPS с самоподписанным серт.
        servers: [{ url: "https://acserver:8006" }]
    grafana:
      loadBalancer:
        servers: [{ url: "http://grafana:3000" }]

  serversTransports:
    insecure-backend:
      insecureSkipVerify: true
```

Что тут стоит знать:

- Это **не редирект**. Traefik принимает TLS на себя и дальше проксирует запрос на бэкенд по обычному HTTP. В адресной строке остаётся `https://имя.dgkagramanyan.ru` — браузер общается только с Traefik.
- Если бэкенд сам живёт на **HTTPS с самоподписанным сертификатом** (как Proxmox или Omada), обычный `http://` не подойдёт — Traefik не достучится. Тогда `url: "https://..."` плюс `serversTransport: insecure-backend`, который говорит «не проверяй сертификат бэкенда» (это внутренний доверенный хоп, наружу всё равно отдаётся нормальный сертификат).
- Контейнер стека (например Grafana) адресуется по имени контейнера — `http://grafana:3000` — но для этого он должен быть в сети `proxy`. Если Traefik не может резолвить имя (`homepc`, `acserver`, `openwrt`), добавь его в `extra_hosts` контейнера traefik в compose.

## Шаг 7. Выпуск сертификата

Порядок такой, чтобы не спалить лимит боевого Let's Encrypt:

1. Раскомментировать `caServer` (staging) в `traefik.yml`, пересоздать контейнер.
2. Дождаться в логе `Server responded with a certificate`. Браузер staging-сертификату не доверяет — это нормально, мы просто проверяем, что вся цепочка работает.
3. Вернуть боевой режим (закомментировать `caServer` обратно), стереть старый сертификат и пересоздать:

```bash
rm letsencrypt/acme.json && touch letsencrypt/acme.json && chmod 600 letsencrypt/acme.json
docker compose up -d --force-recreate
```

4. В логе должно появиться `acmeCA=https://acme-v02...` — без `staging`.

Проверить, какой сертификат реально отдаётся:

```bash
echo | openssl s_client -connect raspberrypi:443 -servername kuma.dgkagramanyan.ru 2>/dev/null | openssl x509 -noout -issuer
```

Издатель `R10`/`R11`/`E5`/`E6` — боевой доверенный. `STAGING` или `Fake LE` — значит ещё staging. Если браузер после выпуска всё равно ругается «не защищено» — это кеш staging-сертификата, лечится жёстким обновлением (Ctrl+Shift+R) или инкогнито.

## Шаг 8. Чтобы внутри сети имена вели прямо на Pi (split-DNS)

Тонкий момент. Публичный DNS указывает поддомены на публичный IP. Но когда я сижу дома и открываю `kuma.dgkagramanyan.ru`, глупо гонять трафик наружу в интернет и обратно. Пусть внутри сети имя сразу ведёт на локальный IP Pi.

Это делается на MikroTik — он у меня отвечает за DNS в локалке:

```
/ip dns static
add regexp="[.]dgkagramanyan[.]ru\$" address=192.168.88.X
add name=dgkagramanyan.ru address=192.168.88.X
/ip dns cache flush
```

`192.168.88.X` — локальный IP Pi (`ip -4 addr show`). Одна regex-запись переопределяет сразу все поддомены. Работает при условии, что `/ip dns print` показывает `allow-remote-requests: yes`, а клиенты используют MikroTik как DNS-сервер.

Приятный бонус: так внутренний трафик не зависит от hairpin NAT (заворота наружу-внутрь), который на MikroTik часто капризничает.

## Шаг 9. Открыть сервис наружу

Весь внешний трафик идёт через Traefik, поэтому пробрасывать нужно только 80 и 443 на Pi — Traefik сам разведёт по хостам. Открывать порт под каждый сервис не надо.

```
/ip firewall nat
add chain=dstnat action=dst-nat protocol=tcp dst-port=80 in-interface-list=WAN to-addresses=192.168.88.X to-ports=80
add chain=dstnat action=dst-nat protocol=tcp dst-port=443 in-interface-list=WAN to-addresses=192.168.88.X to-ports=443
```

Публичный DNS поддомена должен указывать на домашний WAN-IP (`curl ifconfig.me`).

И сразу про безопасность: wildcard делает публично резолвимыми **все** поддомены, а среди них — админки (Proxmox, LuCI, Omada, OpenVPN, дашборд Traefik, Grafana). Их выставлять в интернет нельзя. Закрываем middleware по IP — порт открыт, но отвечает только локалке:

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
      middlewares: [lan-only]   # снаружи прилетит 403
```

Публичные сервисы просто не подключают этот middleware.

## Шаг 10. Проксирование чужого домена (wiki.aripari.am)

Отдельная история — прокинуть через Traefik домен, которого нет в моём wildcard. Бэкенд `170.134.51.33:443` уже отдаёт нормальный Let's Encrypt сертификат для `wiki.aripari.am`, поэтому проще всего скопировать этот сертификат к себе и подключить файлом.

Маршрут (обращаемся к бэкенду по IP, поэтому `insecure-backend` — при обращении по IP имя в сертификате не совпадёт, проверку отключаем):

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

Копируем сертификат с бэкенда (ключ лежит под root, поэтому через временную копию с chown):

```bash
mkdir -p ~/traefik/certs
ssh sysadmin@170.134.51.33 'sudo cp /etc/letsencrypt/live/wiki.aripari.am/{fullchain.pem,privkey.pem} /tmp/ && sudo chown sysadmin /tmp/fullchain.pem /tmp/privkey.pem'
scp sysadmin@170.134.51.33:/tmp/fullchain.pem ~/traefik/certs/wiki.aripari.am.crt
scp sysadmin@170.134.51.33:/tmp/privkey.pem   ~/traefik/certs/wiki.aripari.am.key
chmod 600 ~/traefik/certs/wiki.aripari.am.key
```

Монтируем папку в compose (`- ./certs:/certs:ro`) и объявляем сертификат в `dynamic/certs.yml`:

```yaml
tls:
  certificates:
    - certFile: /certs/wiki.aripari.am.crt
      keyFile: /certs/wiki.aripari.am.key
```

Дальше как обычно: split-DNS на MikroTik (`add name=wiki.aripari.am address=192.168.88.X`) для локалки, публичный DNS + проброс :443 для внешки.

Один нюанс: `fullchain.pem` — это сертификат вместе с цепочкой, брать именно его, а не голый `cert.pem`. И помни, что скопированный сертификат **сам не продлевается** — через ~90 дней истечёт. Либо потом копировать вручную, либо повесить на бэкенде renewal-hook, который после обновления сам зальёт свежие файлы на Pi.

Кстати про грабли: у меня backend сначала не отвечал (Traefik писал `504`). Оказалось, я указал не тот IP — тот, куда форвардит MikroTik снаружи, а не тот, до которого достаёт сам Pi. Если ловишь таймаут — проверь `nc -zv <IP> 443` с самого Pi и поправь `url`.

## Шаг 11. Мониторинг: сколько запросов к каждому сервису

Схема: Traefik отдаёт метрики → Prometheus их собирает → Grafana рисует. Метрики Traefik я уже включил в `traefik.yml` (точка входа `:8082`). Ключевая метрика — `traefik_router_requests_total`, размеченная по роутеру и коду ответа, так что разбивка «сколько запросов к какому сервису» получается бесплатно.

### `prometheus.yml`

Тут была дурацкая ловушка: если папки/файла нет, Docker при монтировании создаёт **каталог** с таким именем, и Prometheus падает с `not a directory`. Файл нужно создать заранее (`rm -rf prometheus.yml`, если уже случайно стал каталогом).

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: traefik
    static_configs:
      - targets: ["traefik:8082"]

  # node_exporter на сервере wiki — метрики железа (CPU, RAM, диск)
  - job_name: wiki-host
    static_configs:
      - targets: ["170.134.51.33:9100"]
        labels: { instance: wiki }
```

### Контейнеры Prometheus и Grafana

Оба в сети `proxy`. Маршрут `grafana.dgkagramanyan.ru` я держу в `native-services.yml` (см. шаг 6), поэтому меток Traefik на контейнере Grafana нет.

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
      - GF_SERVER_ROOT_URL=https://grafana.dgkagramanyan.ru
      - GF_FEATURE_TOGGLES_ENABLE=publicDashboards
      - GF_CACHING_ENABLED=false
    volumes:
      - grafana-data:/var/lib/grafana
    networks: [proxy]

# volumes:
#   prometheus-data:
#   grafana-data:
```

Про эти три переменные окружения я узнал не сразу, все три — из реальных граблей (подробнее ниже в блоке про публичные дашборды).

### Метрики железа wiki-сервера

Чтобы видеть не только трафик, но и загрузку самого сервера, на нём (`170.134.51.33`) поднимается node_exporter. Флаги `pid: host` и монтирование `/` нужны, чтобы он видел настоящую систему хоста, а не своё окружение внутри контейнера:

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

Порт 9100 отдаёт кучу внутренней инфы о системе без всякой авторизации, поэтому его надо закрыть от интернета и пустить только Pi: `ufw allow from <IP_Pi> to any port 9100`.

### Дашборды

Заходим на `https://grafana.dgkagramanyan.ru` (`admin` / пароль), добавляем источник Prometheus с адресом `http://prometheus:9090`, и импортируем готовые дашборды по ID: **17346** (Traefic v3) и **1860** (Node Exporter Full — полное железо).

Пара полезных запросов, если хочется свои панели:

```promql
sum by (router) (rate(traefik_router_requests_total[1m]))                # запросов/сек на сервис
sum by (router) (rate(traefik_router_requests_total{code=~"5.."}[1m]))   # только ошибки 5xx
```

### Публичная ссылка на дашборд (без входа)

Хотелось расшарить дашборд по ссылке, чтобы открывался без логина. В Grafana это `Share → Public dashboard → Enable`. Но тут я собрал почти все грабли, которые есть:

- **Ссылка ведёт на `localhost:3000`.** Grafana не знает свой внешний адрес — лечится переменной `GF_SERVER_ROOT_URL`.
- **На публичной ссылке случайные / устаревшие графики, хотя под логином всё нормально.** Это кеш публичных дашбордов. Отключается `GF_CACHING_ENABLED=false`.
- **Панели пустые («No data»), под логином — есть данные.** Так ведут себя дашборды с template-переменными (`$job`, `$instance` — на них построен и 1860). На публичной ссылке переменные не разворачиваются. Либо зафиксировать переменную на единственный instance (Settings → Variables → задать Current value и Hide), либо сделать дашборд без переменных, где `job` прописан прямо в запросах.
- И вообще: публичный дашборд светит наружу внутренние метрики сервера. Публиковать стоит только то, что не жалко показать.

## Как добавить новый сервис (шпаргалка)

1. Имя уже покрыто wildcard-сертификатом и regex на MikroTik — Selectel трогать не нужно.
2. Дописать пару router + service в `native-services.yml`, указать `url` бэкенда.
3. Если бэкенд на HTTPS с самоподписанным сертификатом — добавить `serversTransport: insecure-backend`.
4. Сохранить файл — Traefik подхватит сам, без перезапуска.
5. Админку — закрыть middleware `lan-only`.

## Грабли, на которые я наступил

| Что видно | В чём было дело |
|---|---|
| `selectelv2: Authentication failed` | У сервисного пользователя нет роли на проекте, или в `PROJECT_ID` попало имя вместо UUID. Проверить curl-тестом (шаг 2). |
| `waiting for record propagation` виснет | Публичные резолверы не видят свежую TXT-запись. Прописать `a.ns.selectel.ru:53` в `resolvers`. |
| `too many failed authorizations (5)` | Упёрся в лимит Let's Encrypt. Перейти на staging и переждать час. |
| Браузер «не защищено» после выпуска | Ещё staging-сертификат или кеш браузера. Проверить издателя через `openssl`, обновить Ctrl+Shift+R. |
| `client version 1.24 is too old` | Старый Traefik не дружит с Docker 29+. Обновить образ до `traefik:v3.7`. |
| `tls: failed to verify certificate: valid for X` | Бэкенд на HTTPS по IP или с самоподписанным серт. Добавить `serversTransport: insecure-backend`. |
| `504` на проксируемый бэкенд | Pi физически не достаёт бэкенд по указанному IP. Проверить `nc -zv host 443`, поправить `url`. |
| `not a directory: mount prometheus.yml` | Docker создал каталог вместо файла. `rm -rf prometheus.yml` и создать файлом. |
| `mapping values are not allowed` | Кривые отступы в YAML. `serversTransport` и `servers` — на одном уровне внутри `loadBalancer`. |
| Grafana public: пусто или случайные графики | Включить `GF_CACHING_ENABLED=false`; зафиксировать template-переменные или взять дашборд без них. |
| Grafana: share-ссылка на `localhost:3000` | Задать `GF_SERVER_ROOT_URL`. |
