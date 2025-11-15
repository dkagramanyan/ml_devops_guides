# Настройка centos10

1) 
```bash
sudo dnf install lua-term lua-filesystem lua-posix
```

```
sudo dnf config-manager --set-enabled crb
sudo dnf clean all
sudo dnf makecache
sudo dnf install lua-devel
```
2) 
```
sudo ./configure --prefix=/opt/apps/lmod
sudo make
sudo make install
```

3) 
```
sudo ln -s /opt/apps/lmod/lmod/lmod/init/profile /etc/profile.d/z00_lmod.sh
sudo ln -s /opt/apps/lmod/lmod/lmod/init/cshrc /etc/profile.d/z00_lmod.csh
```

4) 
```
sudo nano /opt/apps/lmod/lmod/lmod/init/.modulespath
```

```
/opt/apps/modulefiles/Core
/opt/apps/modulefiles/Applications
```

```
sudo nano /opt/apps/modulefiles/Core/hello/1.0.lua
```

5) проверка
```
-- hello/1.0.lua
help([[Hello module version 1.0]])

whatis("Name: hello")
whatis("Version: 1.0")

prepend_path("PATH", "/opt/apps/hello/1.0/bin")
```

```
module avail hello
module load hello/1.0
echo $PATH  # should include /opt/apps/hello/1.0/bin
module unload hello/1.0

```

5) ручная проверка 
```
eval "$(/opt/apps/lmod/lmod/lmod/libexec/lmod bash init)"
module --version
```
