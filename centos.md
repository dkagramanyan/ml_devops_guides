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

```
sudo ./configure --prefix=/opt/apps/lmod
sudo make
sudo make install
```

```
sudo ln -s /opt/apps/lmod/lmod/lmod/init/profile /etc/profile.d/z00_lmod.sh
sudo ln -s /opt/apps/lmod/lmod/lmod/init/cshrc /etc/profile.d/z00_lmod.csh
```


```
eval "$(/opt/apps/lmod/lmod/lmod/libexec/lmod bash init)"
module --version
```
