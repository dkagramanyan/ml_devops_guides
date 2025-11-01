# Hypervisors

## CentOS 10
**доступных гипервизоров нет**

## CentOS 9
Доступны популярные гипервизоры. Завелся oVirt. Он предназначен для промышленного разворачивания ВМ

## Promox

[Скрипты для быстрой установки](https://community-scripts.github.io/ProxmoxVE/)

Лучший гипервизор по соотношению функционала/сложности разворачивания. Особенности
1) поддерживает работу с raid 
2) по умолчанию настроен на обновление пакетов с корпоративного платного репозитория. Нужно поменять конфиги на опенсорные репозитории

```bash
# 1) Remove the old single-line files
rm -f /etc/apt/sources.list.d/ceph.list
rm -f /etc/apt/sources.list.d/pve-no-subscription.list

# 2) Ensure the Proxmox keyring is present (usually already installed)
apt install -y proxmox-archive-keyring || true

# 3) Create Ceph Squid (no-subscription) in deb822 format
cat >/etc/apt/sources.list.d/ceph.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# 4) Create Proxmox VE no-subscription in deb822 format
cat >/etc/apt/sources.list.d/proxmox.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# 5) 
cat >/etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian/
Suites: trixie trixie-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF


# 6) Update
apt update
```

# Raid

[хороший гайд](https://sidmid.ru/программный-raid/)
