Anaconda
--------


## Редкие пакеты

~~~
conda install -c conda-forge ffmpeg-python
~~~

## Установка на apple silicon

При попытке установить tensorflow может возникнуть проблема, что анаконда не может найти нужный пакет. Это связано с тем, что
при установке была выбрана [версия для х86](https://stackoverflow.com/questions/70562033/tensorflow-deps-packagesnotfounderror), которая будет запускаться через rosetta. Решение - переустановить anaconda

