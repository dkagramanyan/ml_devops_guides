WSL
---

## Настройка сети

При установке wsl создается сеть между комньютером windows и виртуальной ubuntu wsl. Эта сеть по умолчанию не имеет связь с локальной сетью, в которой находится компьютер windows. Для решения этой проблемы нужно выбрать одини из алгоритмов

1) пробросить порты через [прокси](https://superuser.com/questions/1717753/how-to-connect-to-windows-subsystem-for-linux-from-another-machine-within-networ)
2) сделать зеркальную [сеть](https://superuser.com/questions/1717753/how-to-connect-to-windows-subsystem-for-linux-from-another-machine-within-networ) (не работает на windows 10, работает на windows 11).  Hyper-V Firewall [не работает на windows 10](https://github.com/microsoft/WSL/discussions/11380)
3) сделать  [мост](https://develmonk.com/2021/06/05/easiest-wsl2-bridge-network-without-hyper-v-virtual-network-manager/) между сетями (не заработало). Рабочий вариант с мостом [тут](https://github.com/microsoft/WSL/discussions/9227#discussioncomment-6764641) (нестабильное решение)

Если нужно сбросить настройки сети в wsl, то команды вот [тут](https://help.nordlayer.com/docs/how-to-reset-network-settings-on-linux)

Самым простым решением является обновление windows до 11 версии, после которого нужно сделать зеркальную сеть с WSL

## Зеркальная сеть WSL 

1) Устанавливается windows 11
2) В конфиге [.wslconfig](https://superuser.com/questions/1765370/cannot-locate-wslconfig-in-user-profile-on-windows-11) пишется следующее
~~~
[wsl2]
networkingMode=mirrored
~~~
После этого у машины wsl будет такой же адрес, как у хоста (компьютера windows)

3) Для назначения вебсерверам, находящимся на wsl, адреса хоста [нужно пропиcать в конфиге](https://github.com/microsoft/WSL/issues/11034#issuecomment-1894295548) следующее
~~~
[experimental]
hostAddressLoopback=True
~~~

по итогу конфиг выглядит так
~~~
[wsl2]
networkingMode=mirrored
memory=30GB
processors=8
[experimental]
hostAddressLoopback=True
~~~

## Запуск скриптов из windows в wsl

Для создания .bat скрипта для запуска jupyter server нужно
1) создать .bat файл следующего содержания. Чтобы предотвратить закрытие консоли после ошибки добавим строчку [отсюда](https://stackoverflow.com/questions/17118846/how-to-prevent-batch-window-from-closing-when-error-occurs)
~~~
@echo off
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )
wsl -e bash -c "cd; ./jupyter_start.sh"
~~~

2) в wsl нужно создать jupyter_start.sh скрипт и внутри написать
~~~
source ~/anaconda3/etc/profile.d/conda.sh

conda activate torch

jupyter lab
~~~

## Запуск сложных скриптов из windows в wsl

~~~
res=subprocess.run('wsl -e bash -c "echo $(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024)))" ', capture_output=True)
res=subprocess.run(['wsl', '-e', 'bash', '-c', 'ps -eo rss | awk \'{sum+=$1} END {print sum/1024}\''], capture_output=True, text=True)

~~~

## Перенос WSL на другой диск

Для переноса есть хороший короткий гайд на [форуме](https://superuser.com/questions/1550622/move-wsl2-file-system-to-another-drive/1618643#1618643)

После переноса нужно обязательно назначить пользователя wsl по умолчанию

~~~
ubuntu config --default-user YourUsername
~~~

После нужно сделать версию wsl по умолчанию в системе

~~~
wsl --set-default Ubuntu
~~~

## Доступ к файлам WSL из windows
Из файловой системы windows есть [доступ](https://superuser.com/questions/1791373/location-of-wsl-home-directory-in-windows) к файловой системе wsl. В адресную строку проводника нужно ввести

~~~
 \\wsl.localhost\Ubuntu\
~~~

## Автостарт WSL при включении windows

Для автостарта нужно создать батник и скачать программу [nircmd](https://www.nirsoft.net/utils/nircmd.html). Решение взято [отсюда](https://www.reddit.com/r/bashonubuntuonwindows/comments/1716np4/start_wsl_on_boot_without_login/).
Затем батник нужно положить в папку автостарт в windows

~~~
@start /b H:\nircmd.exe execmd wsl ~
~~~

## Работа с .vhdx файлом WSL

Для каждого запущенного дистрибутива создается свой виртуальный жесткий диск. Для извлечения файлов из него есть 2 способа

### Конвертировать .vhdx  в .vhd

Конвертировать при помощи [gemu-img](https://cloudbase.it/qemu-img-windows/) или других программ .vhdx  в .vhd и подключить полученный файл в качестве диска в виртуалке Virtualbox/VMware. Решение описано [тут](https://www.reddit.com/r/bashonubuntuonwindows/comments/ok2rk9/how_to_recover_data_from_wsl_2_vhdx_without_using/).

Важно!
1) Конвертация может быть очень долгой, если виртуальный диск большой. Диск размером 170 гб почему-то восприинимается, как диск размером в 1 тб. По этой причине обход всех секторов при помощи r-studio/r-linux по предварительной оценке займет несколько суток
2) Открыть .vhdx каким-нибудь редактором нельзя. Это полноценный виртуальный жесткий диск с своими секторами

### Добавить в список wsl дистрибутивов .vhdx файл

Самый простой и эффективный способ открыть .vhdx - создать из него виртуальную машину командой

```
wsl --import-in-place <distro-name> <path-to-vhdx>
```

Удалить дистрибутив можно командой ниже. Важно! Эта команда удаляет виртуальный диск из директории системы
```
wsl --unregister <distro-name>
```

## Решение ошибок

### Ошибка 

Ошибка ниже решается включением systemd в дистрибутиве wsl. Ошибка описана [тут](https://askubuntu.com/questions/1379425/system-has-not-been-booted-with-systemd-as-init-system-pid-1-cant-operate)
```
System has not been booted with systemd as init system (PID 1). Can't operate.

Failed to connect to bus: Host is down Failed to talk to init daemon.
```

Для решения нужно в в файле wsl.conf  
```
sudo -e /etc/wsl.conf
```

написать строки ниже
```
[boot]
systemd=true
```


