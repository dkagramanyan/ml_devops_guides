# Mikrotik

Если у вас есть белвый ip, то вы можете настроить проброс портов и работать в jupyter сервером удаленно. Важно!
Обязательно нужно использовать SSL сертификат

Для настройки был взят вот этот [гайд](https://spw.ru/educate/articles/natpart5/)


1) fs

~~~
/ip firewall nat
add action=dst-nat chain=dstnat dst-address=1.1.1.1 dst-port=80 protocol=tcp to-addresses=192.168.0.10
~~~

2) ds

~~~
add action=masquerade chain=srcnat dst-address=192.168.0.10 dst-port=80 protocol=tcp src-address=192.168.0.0/24
~~~



