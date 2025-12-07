@echo off
setlocal enabledelayedexpansion

:: Global resources
set VCPU=2
set RAM=2048
set HDD_SIZE=10240
set BASE_DISK=%~dp0ubuntu-24.04-server-cloudimg-amd64.vmdk
set BRIDGE_ADAPTER="Intel(R) Ethernet Connection"

:: Iterate through all folders containing cloud-init.iso
for /d %%D in (*) do (
    if exist "%%D\cloud-init.iso" (
        set VMNAME=%%~nxD
        echo Creating VM !VMNAME! ...

        :: Create VM
        VBoxManage createvm --name "!VMNAME!" --register

        :: Set resources
        VBoxManage modifyvm "!VMNAME!" --cpus %VCPU% --memory %RAM% --vram 16 --nic1 bridged --bridgeadapter1 %BRIDGE_ADAPTER% --boot1 disk --boot2 dvd --boot3 none --boot4 none --graphicscontroller vboxsvga

        :: Add SATA controller
        VBoxManage storagectl "!VMNAME!" --name "SATA Controller" --add sata --controller IntelAhci --portcount 4 --bootable on

        :: Attach base Ubuntu disk
        VBoxManage storageattach "!VMNAME!" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "%BASE_DISK%"

        :: Attach cloud-init ISO
        VBoxManage storageattach "!VMNAME!" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "%%D\cloud-init.iso"

        :: Start VM headless
        VBoxManage startvm "!VMNAME!" --type headless

        echo VM !VMNAME! started.
        echo.
    )
)

echo All VMs processed.
pause