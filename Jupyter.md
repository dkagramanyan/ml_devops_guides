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
jupyter lab --generate-config
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
from jupyter_server.auth import passwd
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

Docker
-----

Юпитерлаб можно запусти ть в докере, список готовых образов [тут](https://quay.io/organization/jupyter). Параметры запуска описаны в [документации](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html)

~~~
docker run \
  -d \
  --restart=always \
  -p 9999:9999 \
  --user root \
  -e GRANT_SUDO=yes\
  -v "/mnt/c/ssl_certificates:/ssl_certificates" \
  -v "$(pwd)/rag/:/home/jovyan/work" \
  --gpus=all \
  quay.io/jupyter/pytorch-notebook:cuda12-pytorch-2.4.1 \
  start-notebook.py \
  --NotebookApp.token='8PVzAM1ZaSIY6FZ1cZEe5gqH2t3yuhs13OOlZeQyRtjQxheW6JbgVOgP483' \
  --NotebookApp.port='9999' \
  --NotebookApp.certfile='/ssl_certificates/certificate.crt' \
  --NotebookApp.keyfile='/ssl_certificates/certificate.key'
~~~

JupyterHub
---------

При обычном запуске jupyterHub через команду, могут возникнуть ошибки из-за того, что [не хватает прав](https://discourse.jupyter.org/t/starting-server-for-non-default-users-in-jupyterhub-500-internal-server-error/21518). [Решается запуском юпитерхаба в докере](https://discourse.jupyter.org/t/starting-server-for-non-default-users-in-jupyterhub-500-internal-server-error/21518) 
