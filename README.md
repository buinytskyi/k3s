# K3s Cluster Setup with VirtualBox

This repository provides scripts to automate the preparation of cloud-init config disk, installation of required tools, and creation of VirtualBox VMs for running a lightweight Kubernetes (K3s) cluster.

---

## Prerequisites
- Debian/Ubuntu for preparing cloud-init ISO images
- Internet access to download required packages and VM images

---

## Prepare Cloud-Init Disk Config
Use the provided script to generate cloud-init ISO images for master and worker nodes.

```bash
./cloud-init-k3s.sh
```
## Download/install VirtualBox, HELM, Kubernetes CLI, VM image
```bash
./install-tools.sh
```

## Create VMs by VBoxManage