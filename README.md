# K3s Cluster Setup with VirtualBox

This repository provides scripts to automate the preparation of cloud-init config disk, installation of required tools, and creation of VirtualBox VMs for running a lightweight Kubernetes (K3s) cluster.

---

## Prerequisites
- Linux (Debian/Ubuntu) for preparing cloud-init ISO images
- Windows with VirtualBox installed for running VMs
- Internet access to download required packages and VM images

---

## Step 1: Prepare Cloud-Init Disk Config (Linux)
Use the provided script to generate cloud-init ISO images for master and worker nodes.

```bash
./cloud-init-k3s.sh
```
## Step 2: Download/install VirtualBox, HELM, Kubernetes CLI, VM image (Windows/Linux)
```
install-tools.bat
install-tools.sh
```

## Step 3: Create VMs by VBoxManage (Windows)
```
run-vm.bat
```