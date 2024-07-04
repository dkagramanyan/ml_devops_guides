Apple silicon
--------------------------------

Хорошо описано [тут](https://jamescalam.medium.com/hugging-face-and-sentence-transformers-on-m1-macs-4b12e40c21ce) 

Установка Tensorflow
~~~~~~~~~~~~~~~~~~~~

При попытке установить tensorflow может возникнуть пробелма, что анаконда не может найти нужный пакет. Это связано с тем, что
при устанвоке была выбрана версия для х86, которая будет запускаться через rosetta

[тут](https://stackoverflow.com/questions/70562033/tensorflow-deps-packagesnotfounderror)
