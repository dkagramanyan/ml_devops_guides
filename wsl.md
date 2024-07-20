WSL
---

При установке wsl создается сеть между комньютером windows и виртуальной ubuntu wsl. Эта сеть по умолчанию не имеет связь с локальной сетью, в которой находится компьютер windows. Для решения этой проблемы нужно выбрать одини из алгоритмов

1) пробросить порты через [прокси](https://superuser.com/questions/1717753/how-to-connect-to-windows-subsystem-for-linux-from-another-machine-within-networ)
2) сделатть заркальную сеть (не работает на windows 10, работает на windows 11).  Hyper-V Firewall не работает на windows 10
3) сделать мост между сетями (не заработало). Рабочий вариант с мостом тут (нестабильное решение). Важно, что по итогу в powershell были испольщованф следующие команды

Set-VMSwitch -name "WSL" -NetAdapterName "Ethernet" -AllowManagementOS $true

Из файлово системы windows есть доступ к файловой системе wsl. В адресную строку проводника нужно ввести

~~~
 \\wsl.localhost\Ubuntu\
~~~

Если нужно сбросить настройки сети в wsl, то команды вот тут
