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
