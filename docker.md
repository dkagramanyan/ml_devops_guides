# Docker

## Ошибка package 'docker-ce' has no installation candidate

При установке докера может возникнуть ошибка, что пакеты не доступны для установки
```
package 'docker-ce' has no installation candidate ubuntu 22.04
```
Для решения проблемы нужно скачать пакеты напрямую с сайта докера. Описано [тут](https://askubuntu.com/questions/1468289/docker-install-error)


## Ошибка GPG error
При скачивании пакетов может возникнуть ошибка отсутствия GPG ключа. 
```
GPG error: https://download.docker.com/linux/ubuntu jammy InRelease:
The following signatures couldn't be verified because the public
 key is not available: NO_PUBKEY 7EA0A9C3F273FCD8
```

Решается скачиванием GPG ключа с сайта докера. Описано [тут](https://stackoverflow.com/a/69986013)
