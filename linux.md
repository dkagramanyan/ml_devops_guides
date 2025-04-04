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
  --name=openvpn \
  --device /dev/net/tun \
  --cap-add=MKNOD --cap-add=NET_ADMIN \
  --pull always \
  -p 943:943 -p 443:443 -p 1194:1194/udp \
  -v ovpn_data:/openvpn \
  --restart=unless-stopped \
  openvpn/openvpn-as
```

```
sudo docker run openvpn
```

Kuma alerts
----------

```
docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:1
```

## Монтирование дисков

Если диски были изначально созданы в windiws и при каждом запуске ubuntu нужно их монтировать руками, то есть [решение](https://askubuntu.com/questions/966706/17-10-how-to-auto-mount-drives-on-startup)

```
sudo blkid # определяем UUID дисков
```

В конфе файла /etc/fstab добавляем строки

```
UUID=B4BE2F86BE2F3FEA /media/david/work_ssd_0.5 ntfs defaults 0 0
UUID=14A25E84A25E6A6E /media/david/storage_hard_1 ntfs defaults 0 0
UUID=70F6C51AF6C4E208 /media/david/work_ssd_2_sata ntfs defaults 0 0
UUID=8AC6984BC6983A01 /media/david/storage_hard_2 ntfs defaults 0 0
```


## Темы для терминала zsh
1) [oh-my-zash](https://dev.to/dinhkhai0201/how-to-install-oh-my-zsh-and-zsh-autosuggestions-for-macbook-3f07)

## Наполнение файла .zshrc

```
# homebrew do not delete
export PATH=/opt/homebrew/bin:$PATH

export PATH=$HOME/anaconda3/bin:$PATH

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
```

Прочее
------

1) запуск задач по таймеру [cronlab](https://askubuntu.com/questions/13730/how-can-i-schedule-a-nightly-reboot)
2) настройка [XRDP](https://serverspace.ru/support/help/how-to-xrdp-ubuntu-20.04/?utm_source=google.com&utm_medium=organic&utm_campaign=google.com&utm_referrer=google.com)
3) если при подключении по XRDP вылезает *system policy prevents wifi scans*, то вот [решение](https://unix.stackexchange.com/questions/782724/newbie-system-policy-prevents-wi-fi-scans)
