# SSH troubleshooting

## Ошибка 1

Ubuntu 22.04 wsl2
```
user@domain: Permission denied (publickey).
```

Решение - в конфиге ssh поставить следубщие параметры. Описано [тут](https://askubuntu.com/questions/1252937/unable-to-connect-to-basic-ubuntu-ssh-server-with-password-authentication-perm)
```
PermitRootLogin yes
PubkeyAuthentication no
PasswordAuthentication yes
PermitEmptyPasswords no
KbdInteractiveAuthentication yes
```

## Ошибка 2

Если не устанавливается openssh-server. Описано [тут](https://askubuntu.com/questions/265982/unable-to-start-sshd) и [тут](https://askubuntu.com/questions/603493/apt-get-dependency-issue-open-ssh-client)
```
sudo apt-get purge openssh-server
sudo apt-get install openssh-server
```


## Настройка ключа для подключения к машине ubuntu по ssh

```
ssh-keygen
ssh-copy-id -i .ssh/id_ed25519.pub david@homepc
```
