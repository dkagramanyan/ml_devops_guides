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

