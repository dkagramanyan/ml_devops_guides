# Настройка фильтрации и перенаправления трафика на впн тоннель

Алгоритм действий
1) покупаем роутер вида AX3000T от xiaomi. Роутер должен обладать характеристиками, указанными на странице проекта [Podkop](https://github.com/itdoginfo/podkop)
2) накатываем на него OpenWRT. Скачиваем прошивку sysapgrade [тут](https://firmware-selector.openwrt.org/?version=24.10.2). Выбираем прошивку только с названием роутера без дополнительных фраз в скобках
3) в interfaces->wan настраиваем подключение к интернету по данным от провайдера
4) подключаемся по витой паре к роутеру по ssh. Обязательно перед этим ставим пароль в OpenWRT, этот пароль будет паролем root  Важно, что после установки OpenWRT по умолчанию выключен wifi. При необходимости его можно включить. При подключении wifi нужно в поле Network добавить настроенный wan
```bash
ssh root@192.168.1.1
```
4) запускаем скрипт из ридми [Podkop](https://github.com/itdoginfo/podkop)
5) выходим из учетки openwrt, заходим обратно
6) services->Podkop->вставляем vless ключ в поле Proxy Configuration URL
7) применяем изменения и радуемся

## Если перенаправляющий роутер стоит до основного роутера

То есть, если wan второго роутера идет в lan первого роутера

В втором (основном) роутере
1) обятельно сбрасываем кеш в DNS сервере

При верной настройке из локальной сети второго роутера будет доступен основной роутер по адресу 192.168.1.1

Также дополнительно в первом роутере нужно сделать:
1) делаем переброс портов в OpenWRT: network->firewall->port forwarding, указываем целевую подсеть (ту, в которую будем перенаправлять запросы) и адрес второго роутера в подсети первого роутера. Так все запросы, приходящие на роутер OpenWRT, будут переадресовываться на второй роутер
2) делаем статический ip адрес второго роутера в разделе DHCP

При создании NAT правил в втором роутере нужно указывать source ip adress в виде локального ip адреса второго роутера в сети первого роутера. В моем случае это 192.168.1.231

## Настройка доступа веб панели oepnwrt из локальной сети mikrotik и локлаьной сети openvpn 

1) в мироктике добавляем в route
   dst. adress 192.168.1.0/24; gateway ehter1 (порт, через который подключен микротик к openwrt)
2) в openwrt в static route
   target 170.134.51.0/24; gateway 192.168.1.231; route type unicast; table main

### Добавление кастомных доменов

Если в готовом списке доменов нет нужного, то можно добавить свои домены
1) basic settings->User domain list

```
api.github.com
api.individual.githubcopilot.com
```

## Anydeks

Автостарт anydesk при запуске ubuntu

```
sudo systemctl enable anydesk.service
sudo systemctl status anydesk.service
```

## 3X-UI
---------

Важно! Если сервис поднимается на машине в локальной сети, к которой трафик будет идти через переброс портов, то поле **ip** при натсройке сервера нужно оставить пустым и в итоговой ссылке клиента нужно заменить ip адрес сервера на домен

По умолчанию 3X-UI поддерживает работу только на [хосте](https://www.metalnikovg.ru/blog/dvoynoe-tunnelirovanie-trafika-s-pomojyu-paneli-3xui)

```
services:
  3xui:
    image: ghcr.io/mhsanaei/3x-ui:latest
    container_name: 3xui_app
    # hostname: yourhostname <- optional
    volumes:
      - $PWD/db/:/etc/x-ui/
      - $PWD/cert/:/root/cert/
      - /home/david/ssl_certificates:/etc/letsencrypt/
    environment:
      XRAY_VMESS_AEAD_FORCED: "false"
      XUI_ENABLE_FAIL2BAN: "true"
    tty: true
    network_mode: host
    restart: unless-stopped
```

```
/ip firewall filter
add chain=forward action=accept protocol=tcp \
    src-address=192.168.1.0/24 \
    dst-address=170.134.51.13 dst-port=2053 \
    comment="Allow 3x ui web ONLY from LAN"
```

```
/ip firewall filter
add chain=forward action=drop protocol=tcp \
    dst-address=170.134.51.13 dst-port=2053 \
    in-interface-list=WAN \
    comment="DROP 3x ui web panel from WAN"
```
