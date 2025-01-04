Anaconda
-------

Если при установке анаконды терминал все равно пишет, что "conda: command not found", то нужно в консоли [экспортнуть](https://saturncloud.io/blog/understanding-the-export-path-command-a-deep-dive-into-export-pathanaconda3binpath/) путь анаконды в .bashrc

~~~
export PATH=~/anaconda3/bin:$PATH
~~~

Для mac os проблема решается так же. Возможное решение описано  [тут](https://stackoverflow.com/questions/35029029/jupyter-notebook-command-does-not-work-on-mac)

Для windows нужно добавить в Path директорию, куда установлена анаконды
```
C:\ProgramData\anaconda3\Scripts
```



## Редкие пакеты

~~~
conda install -c conda-forge ffmpeg-python
~~~

## Установка на apple silicon

При попытке установить tensorflow может возникнуть проблема, что анаконда не может найти нужный пакет. Это связано с тем, что
при установке была выбрана [версия для х86](https://stackoverflow.com/questions/70562033/tensorflow-deps-packagesnotfounderror), которая будет запускаться через rosetta. Решение - переустановить anaconda

