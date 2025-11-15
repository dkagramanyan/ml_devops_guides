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


## XRDP для ubuntu

[Гайд](https://reg.cloud/support/cloud/oblachnyye-servery/ustanovka-programmnogo-obespecheniya/kak-podklyuchitsya-k-ubuntu-iz-windows-s-pomoshchyu-rdp#2) по удаленному подключению к убунте через rdp. 

Важно! **Не нужно** устанавливать графическое окружение Xfce. 

Запуск задач на фоне
--------------------

Для запуска процессов на фоне можно использовать команду [nohup](https://phoenixnap.com/kb/linux-run-command-background):
~~~
nohup jupyter lab &
~~~

Поиск nohup задач
```
jobs -l
```

Label-studio
------------

```
sudo docker run -it -d -p 8080:8080 -v $(pwd)/mydata:/label-studio/data --restart unless-stopped  heartexlabs/label-studio:latest
```

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

## 3X-UI
---------

Важно! Если сервис поднимается на машине в локальной сети, к которой трафик будет идти через переброс портов, то поле **ip** при натсройке сервера нужно оставить пустым и в итоговой ссылке клиента нужно заменить ip адрес сервера на домен

По умолчанию 3X-UI поддерживает работу только на [хосте](https://www.metalnikovg.ru/blog/dvoynoe-tunnelirovanie-trafika-s-pomojyu-paneli-3xui)

```
sudo docker run -d \
	 -e XRAY_VMESS_AEAD_FORCED=false \
	 -e XUI_ENABLE_FAIL2BAN=true \
	 -v $PWD/db/:/etc/x-ui/ \
	 -v $PWD/cert/:/root/cert/ \
	 --network=host \
	 --restart=unless-stopped \
	 ghcr.io/mhsanaei/3x-ui:latest
```


## Монтирование дисков

Если диски были изначально созданы в windiws и при каждом запуске ubuntu нужно их монтировать руками, то есть [решение](https://askubuntu.com/questions/966706/17-10-how-to-auto-mount-drives-on-startup)

```
sudo blkid # определяем UUID дисков
```

В конфе файла /etc/fstab добавляем строки

```
UUID=B4BE2F86BE2F3FEA /home/david/mnt/ssd_0.5_nvme ntfs-3g defaults,nofail 0 2
UUID=70F6C51AF6C4E208 /home/david/mnt/ssd_2_sata ntfs-3g defaults,nofail 0 2

UUID=14A25E84A25E6A6E /home/david/mnt/hdd_1 ntfs-3g defaults,nofail 0 2
UUID=8AC6984BC6983A01 /home/david/mnt/hdd_2 ntfs-3g defaults,nofail 0 2
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

## Запуск десктопных приложений через веб-интерфейс

На ресурсе [linux server io ](https://docs.linuxserver.io/images/docker-obsidian/) много приложений в контейнерах, запущенные через [KasmVNC](https://www.kasmweb.com/kasmvnc). Для некоторых ресурсоемких приложений (например, obsidian), может
потребоваться дополнительная настройка отображения картинки. По умолчанию может быть задержка и низкое разрешение

## Выключение блокировки экрана и выхода из аккаунта ubuntu

```
# If you don’t actually need the screen to lock after idling, you can simply turn off Gnome’s lock:
gsettings set org.gnome.desktop.screensaver lock-enabled false

# To also prevent the “blank‐screen” (so it never even goes to a blank screen), you can disable the idle‐blank:
gsettings set org.gnome.desktop.session idle-delay 0
```

## Виртуализация KVM

[Гайд](https://trueconf.ru/blog/baza-znaniy/nastroyka-gipervizora-kvm-na-ubuntu-server?utm_source=google.com&utm_medium=organic&utm_campaign=google.com&utm_referrer=google.com) по установке и запуску ВМ 

Прочее
------

1) запуск задач по таймеру [cronlab](https://askubuntu.com/questions/13730/how-can-i-schedule-a-nightly-reboot)
2) настройка [XRDP](https://serverspace.ru/support/help/how-to-xrdp-ubuntu-20.04/?utm_source=google.com&utm_medium=organic&utm_campaign=google.com&utm_referrer=google.com)
3) если при подключении по XRDP вылезает *system policy prevents wifi scans*, то вот [решение](https://unix.stackexchange.com/questions/782724/newbie-system-policy-prevents-wi-fi-scans)
