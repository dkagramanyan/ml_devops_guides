WSL
---


При установке wsl создается сеть между комньютером windows и виртуальной ubuntu wsl. Эта сеть по умолчанию не имеет связь с локальной сетью, в которой находится компьютер windows. Для решения этой проблемы нужно выбрать одини из алгоритмов

1) пробросить порты через [прокси](https://superuser.com/questions/1717753/how-to-connect-to-windows-subsystem-for-linux-from-another-machine-within-networ)
2) сделатть зеркальную [сеть](https://superuser.com/questions/1717753/how-to-connect-to-windows-subsystem-for-linux-from-another-machine-within-networ) (не работает на windows 10, работает на windows 11).  Hyper-V Firewall [не работает на windows 10](https://github.com/microsoft/WSL/discussions/11380)
3) сделать  [мост](https://develmonk.com/2021/06/05/easiest-wsl2-bridge-network-without-hyper-v-virtual-network-manager/) между сетями (не заработало). Рабочий вариант с мостом [тут](https://github.com/microsoft/WSL/discussions/9227#discussioncomment-6764641) (нестабильное решение)

Из файловой системы windows есть [доступ](https://superuser.com/questions/1791373/location-of-wsl-home-directory-in-windows) к файловой системе wsl. В адресную строку проводника нужно ввести

~~~
 \\wsl.localhost\Ubuntu\
~~~

Если нужно сбросить настройки сети в wsl, то команды вот [тут](https://help.nordlayer.com/docs/how-to-reset-network-settings-on-linux)

## Легкая настройка сети

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
[experimental]
hostAddressLoopback=True
~~~
