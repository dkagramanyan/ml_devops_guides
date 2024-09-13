Tmux
----
Менеджер консолей. [Документация](https://help.ubuntu.ru/wiki/byobu)

Управление самим tmux осуществляется через предварительное нажатие CTRL + A

1) CTRL+A затем CTRL+D - выход из tmux
2) CTRL+A затем % - сплит экрана горизонтально, в новом сплите запускается новый шелл
3) CTRL+A затем | - сплит экрана вертикально
4) CTRL+A  затем стрелки курсора - смена фокуса
5) CTRL+A затем CTRL+C - новое окно / tab
6) CTRL+A, затем 0, 1 ... 9 - переключится на tab
7) CTRL+A затем CTRL+N - переключится на следующее окно
8) CTRL+D - закрыть шелл, закрыть окно / сплит
9) CTRL+A затем  CTRL+Z - зум текущего окна


Anaconda
-------

Если при установке анаконды терминал все равно пишет, что "conda: command not found", то нужно в консоли [экспортнуть](https://saturncloud.io/blog/understanding-the-export-path-command-a-deep-dive-into-export-pathanaconda3binpath/) путь анаконды в .bashrc

~~~
export PATH=~/anaconda3/bin:$PATH
~~~

Запуск задач на фоне
--------------------

Для запуска процессов на фоне можно исопльщовать команду [nohup](https://phoenixnap.com/kb/linux-run-command-background):
~~~
nohup jupyter lab &
~~~
