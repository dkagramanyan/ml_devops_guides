# Installing NVIDIA Drivers and CUDA on Rocky Linux 9 (9.6 / 9.7)

This guide covers **clean, reproducible installation** of NVIDIA GPU drivers and CUDA on Rocky Linux 9.
It explicitly handles **new-generation GPUs (Ada / Blackwell, e.g. RTX 40xx / 50xx)** that **require NVIDIA Open Kernel Modules**.

---

## 0. Assumptions and scope

* OS: Rocky Linux 9.x
* Kernel: stock RHEL kernel (5.14.x)
* GPU: NVIDIA (consumer or data center)
* Goal: working `nvidia-smi`, CUDA (`nvcc`), stable DKMS across kernel updates

---

## 1. Verify GPU visibility

Before installing anything, confirm the GPU is visible to the OS:

```bash
lspci | grep -i nvidia
```

If **no NVIDIA device appears**, CUDA will not work (BIOS / passthrough issue).

---

## 2. System preparation

### 2.1 Update system

```bash
sudo dnf upgrade --refresh -y
sudo reboot
```

### 2.2 Enable required repositories

```bash
sudo dnf install -y epel-release
echo 'enabled=1' | sudo tee -a /etc/yum.repos.d/rocky-crb.repo
```

### 2.3 Install build dependencies

```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
  kernel-devel-$(uname -r) \
  kernel-headers-$(uname -r) \
  dkms \
  elfutils-libelf-devel \
  libglvnd-devel
```

---

## 3. Disable Nouveau (mandatory)

```bash
sudo grubby --args="rd.driver.blacklist=nouveau nouveau.modeset=0" --update-kernel=ALL
sudo dracut --force
sudo reboot
```

---

## 4. Add NVIDIA CUDA repository

```bash
sudo dnf config-manager --add-repo \
https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
sudo dnf clean all
```

---

## 5. Choose the correct driver type (CRITICAL)

### 5.1 Determine GPU generation

```bash
lspci -nn | grep NVIDIA
```

* **RTX 20xx / 30xx / A100, etc.** → proprietary driver works
* **RTX 40xx / 50xx / GB20x** → **OPEN kernel modules REQUIRED**

If unsure, assume **open kernel modules**.

---

## 6. Install NVIDIA driver (OPEN kernel modules – recommended)

### 6.1 Reset any previous NVIDIA module state

```bash
sudo dnf module reset -y nvidia-driver
```

### 6.2 Install Open Kernel Module stream

```bash
sudo dnf module install -y nvidia-driver:open-dkms
```

This installs:

* Open (GPL) NVIDIA kernel modules
* DKMS auto-rebuild support
* NVML compatible with CUDA

---

## 7. Install CUDA Toolkit

```bash
sudo dnf install -y cuda-toolkit
```

CUDA installs under:

```
/usr/local/cuda-<version>
```

---

## 8. Configure environment variables

```bash
echo 'export CUDA_HOME=/usr/local/cuda' >> ~/.bashrc
echo 'export PATH=$CUDA_HOME/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

---

## 9. Reboot

```bash
sudo reboot
```

---

## 10. Verification (order matters)

### 10.1 Kernel module type

```bash
modinfo nvidia | grep license
```

Expected:

```
license: GPL
```

### 10.2 GPU initialization

```bash
nvidia-smi
```

Expected output includes GPU name and driver version.

### 10.3 CUDA compiler

```bash
nvcc --version
```

---

## 11. Troubleshooting

### 11.1 `nvidia-smi: No devices were found`

Check kernel log:

```bash
dmesg | grep -E "NVRM|nvidia"
```

If you see:

```
requires use of the NVIDIA open kernel modules
```

→ you are using the proprietary driver on a GPU that requires open modules.

### 11.2 Secure Boot

```bash
mokutil --sb-state
```

If enabled, either disable Secure Boot or sign NVIDIA modules.

---

## 12. Version locking (recommended)

Prevent accidental breakage:

```bash
sudo dnf install -y dnf-plugin-versionlock
sudo dnf versionlock add nvidia-driver\* cuda\*
```

---

# Docker

## 1 

```
sudo systemctl stop docker
sudo systemctl stop docker.socket

sudo mkdir -p /home/docker-data
sudo nano /etc/docker/daemon.json
```

add 
```
{
  "data-root": "/home/docker-data"
}
```

```
sudo rsync -aP /var/lib/docker/ /home/docker-data/
sudo systemctl start docker
docker info | grep "Docker Root Dir"
```

```
sudo rm -rf /var/lib/docker
```

## 2

```
sudo systemctl stop docker docker.socket containerd

sudo mkdir -p /home/containerd-data
sudo rsync -aP /var/lib/containerd/ /home/containerd-data/
sudo rm -rf /var/lib/containerd
sudo ln -s /home/containerd-data /var/lib/containerd

sudo systemctl start containerd docker

# Verify
docker images
df -h
```

## 3

```
cd /opt
sudo mkdir services
sudo mv /opt/services /home/services
sudo ln -s /home/services /opt/services
```

# GPUStack

```
sudo firewall-cmd --permanent --add-port=10150/tcp
sudo firewall-cmd --permanent --add-port=10151/tcp
sudo firewall-cmd --permanent --add-port=40000-40063/tcp
sudo firewall-cmd --permanent --add-port=41000-41999/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
```

This setup is **stable, future-proof, and compatible with new-generation NVIDIA GPUs on Rocky Linux 9**.
