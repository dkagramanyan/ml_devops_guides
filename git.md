## Git

Если вам нужно удалить бинарные файлы (которые возникли при отслеживании изображений, pdf и всего того, что не код)  
из истории коммитов git, то это можно сделать ТОЛЬКО 
при помощи  переписывания истории директории .git

Важно: этот способ очистит issues репозитория, но при этом сохранит всю историю коммитов

Для очистки истории требуется:

1) скачать [.jar](https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar) файл 
утилиты [bfg-repo-cleaner](https://rtyley.github.io/bfg-repo-cleaner/).
Полностю клонировать утилиту не нужно. Достаточно скачать рабочий файл .jar
2) установить [Java JDK](https://www.oracle.com/java/technologies/downloads/)
3) склонировать копию репозитория

        git clone --mirror my-repo.git

4) выполнить команду, где в скобках указываются расширения, файлы которых нужно удалить из истории

        java -jar bfg.jar --delete-files '*.{png,PNG}' my-repo.git

5) в директории репозитория выоплнить 
    
        git reflog expire --expire=now --all && git gc --prune=now --aggressive
        git gc

6) в директории выполнить git push. С большой вероятностью у вас может быть ошибки в стиле

         ! [remote rejected] refs/pull/1/head -> refs/pull/1/head (deny updating a hidden ref)

Для решения ошибки нужно удалить репозиторий с GitHub, создать его заново с таким же именем и затем в 
локальной директории репозитория сделать git push новой истории. Вся история коммитов сохранится, но остальное - нет.


## Если git просит логин/пароль при каждом git push

[Решение](https://stackoverflow.com/questions/11403407/git-asks-for-username-every-time-i-push)

```
git config credential.helper store
git push http://example.com/repo.git
```
