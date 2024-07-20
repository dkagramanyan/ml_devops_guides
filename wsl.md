WSL
---

При установке wsl создается сеть между комньютером windows и виртуальной ubuntu wsl. Эта сеть по умолчанию не имеет связь с локальной сетью, в которой находится компьютер windows. Для решения этой проблемы нужно выбрать одини из алгоритмов

1) пробросить порты через [прокси](https://superuser.com/questions/1717753/how-to-connect-to-windows-subsystem-for-linux-from-another-machine-within-networ)
2) сделатть зеркальную [сеть](https://superuser.com/questions/1717753/how-to-connect-to-windows-subsystem-for-linux-from-another-machine-within-networ) (не работает на windows 10, работает на windows 11).  Hyper-V Firewall [не работает на windows 10](https://github.com/microsoft/WSL/discussions/11380)
3) сделать  [мост](https://develmonk.com/2021/06/05/easiest-wsl2-bridge-network-without-hyper-v-virtual-network-manager/) между сетями (не заработало). Рабочий вариант с мостом [тут](https://github.com/microsoft/WSL/discussions/9227#discussioncomment-6764641) (нестабильное решение). Важно, что по итогу в powershell были использованы следующие команды. Вторая команда не нужна

~~~
Set-VMSwitch -name "WSL" -NetAdapterName "Ethernet" -AllowManagementOS $true
~~~


Из файловой системы windows есть [доступ](https://superuser.com/questions/1791373/location-of-wsl-home-directory-in-windows) к файловой системе wsl. В адресную строку проводника нужно ввести

~~~
 \\wsl.localhost\Ubuntu\
~~~

Если нужно сбросить настройки сети в wsl, то команды вот тут
