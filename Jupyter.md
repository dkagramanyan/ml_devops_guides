## Jupyter

### Базовая настройка jupyter notebook/lab

1) Создается окружение Anaconda/venv

2) В новое окружение устанавливается ядро ipython, на котором работает jupyter
~~~
pip install jupyterlab
pip install --user ipykernel
~~~

3) Далее добавить ядро окружения в список ядер jupyter. Не совсем ясно какая за этим стоит логика, но без этой операции jupyter не будет видеть ядра. Также без этой процедуры различные IDE [DataSpell](https://www.jetbrains.com/ru-ru/dataspell/) также не будут видеть ядро
   
~~~
python -m ipykernel install --user --name=$env_name$
~~~

При необходимости можно удалить ядро из jupyter
~~~
jupyter kernelspec uninstall $env_name$
~~~

4) запуск jupyter 

~~~
jupyter lab
~~~

Это минимальный набор для работы с ноутбуками

-----------

### Полная настройка

Для настройки рекумендуется предварительно создать конфиг-файл для юпитера. Это делается командой

~~~
jupyter notebook --generate-config
~~~

Созданный конфиг будет находиться по адресу (для windows)

~~~
/users/{your_user}/.jupyter
~~~

1) Укажем путь, где будет запускаться юпитер сервер. Для этого есть 2 пути
   1) **для windows** Войдите в свойства ярлыка jupyter-> объект -> замените "%USERPROFILE%/" на требуемую директорию. Например
      ~~~
      "D:\PROJECTS\python"
      ~~~

   2) **для всех**. В конфиг вносятся изменения
      ~~~
      #c.NotebookApp.notebook_dir = '/your/folder/path'
      ~~~

2) Поставим пароль. Для этого генерируем скриптом хэш пароля и вносим его в конфиг сервера [guide](https://stackoverflow.com/questions/66063686/set-jupyter-lab-password-encrypted-with-sha-256)

~~~
from notebook.auth import passwd
my_password = "spam-and-eggs"
hashed_password = passwd(passphrase=my_password, algorithm='sha256')
print(hashed_password)
~~~

В конфиге добавляем хеш пароля

~~~
c.NotebookApp.password = u'sha256:bcd259ccf...<your hashed password here>'
~~~

3) изменим айпишник, чтобы можно было извне стучаться к серверу. Для этого нужно изменить конфиг

~~~
c.ServerApp.ip ='xxx.xxx.xxx.xxx'
~~~

4) Если для запуска jupyter используете windows, то можно создать батник для запуска простого сервера. Для этого нужно осздать файл start.bat и внутри прописать

~~~
@echo off
call activate  base
cd /D d:/python

jupyter lab
~~~

5) Для подключения SSL сертификата можно его или выпустить самому, или купить его за 1500р в год на reg.ru. Важно, что перед этим у вас должен быть куплен домен, к которому вы подключите  SSL сертификат. Также обязательно в настройках домена нужно указать, чтобы при обращении к домену проиходил редирект запроса на айпишник, где у вас будет работать Jupyter server

После покупки SSL сертификата сервис вам вернет 4 файла, и которых вам нужно только 2. Их пути нужно будет указать в конфиге jupyter

~~~
# c.ServerApp.certfile = ''
# c.ServerApp.keyfile = ''
~~~
