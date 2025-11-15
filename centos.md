# Настройка centos10

```bash
sudo dnf install lua-term lua-filesystem lua-posix
```

```
sudo dnf config-manager --set-enabled crb
sudo dnf clean all
sudo dnf makecache
sudo dnf install lua-devel
```
