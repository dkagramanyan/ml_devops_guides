Tmux
----
Менеджер консолей. [Документация](https://help.ubuntu.ru/wiki/byobu)

Управление самим tmux осуществляется через предварительное нажатие CTRL + A

1) CTRL+A затем CTRL+D - выход из tmux
2) CTRL+A затем % - сплит экрана горизонтально, в новом сплите запускается новый шелл
3) CTRL+A затем | - сплит экрана вертикально
4) CTRL+A  затем стрелки курсора - смена фокуса
5) CTRL+A затем CTRL+C - новое окно / tab
6) CTRL+A, затем 0, 1 ... 9 - переключится на tab
7) CTRL+A затем CTRL+N - переключится на следующее окно
8) CTRL+D - закрыть шелл, закрыть окно / сплит
9) CTRL+A затем  CTRL+Z - зум текущего окна


Запуск задач на фоне
--------------------

Для запуска процессов на фоне можно использовать команду [nohup](https://phoenixnap.com/kb/linux-run-command-background):
~~~
nohup jupyter lab &
~~~

OpenVPN
-------

Для настройки нужно следовать инструкциям на официальном сайте. После нужно создать конфиг с галочкой о шифровании

```
sudo docker run -d \
  --device /dev/net/tun \
  --cap-add=MKNOD --cap-add=NET_ADMIN \
  --pull always \
  -p 943:943 -p 443:443 -p 1194:1194/udp \
  -v ovpn_data:/openvpn \
  --restart=unless-stopped \
  openvpn/openvpn-as
```

Kuma alerts
----------

```
docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:1
```

Прочее
------

1) запуск задач по таймеру [cronlab](https://askubuntu.com/questions/13730/how-can-i-schedule-a-nightly-reboot)
