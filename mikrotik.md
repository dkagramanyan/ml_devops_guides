# Mikrotik

Если у вас есть белвый ip, то вы можете настроить проброс портов и работать в jupyter сервером удаленно. Важно!
Обязательно нужно использовать SSL сертификат

Для настройки был взят вот этот [гайд](https://spw.ru/educate/articles/natpart5/)

Пусть ваш белвый ip это 100.100.100.100, локальная сеть имеет такие адреса 192.168.88.xxx/24, адрес компьютера 192.168.88.53 и порт, на котором запущен юпитер, 8888. 


1) fs

~~~
/ip firewall nat
add action=dst-nat chain=dstnat dst-address=100.100.100.100 dst-port=443 protocol=tcp to-addresses=192.168.88.53 to-port=8888
~~~

2) ds

~~~
add action=masquerade chain=srcnat dst-address=192.168.88.53 dst-port=8888 protocol=tcp src-address=192.168.88.0/24
~~~



