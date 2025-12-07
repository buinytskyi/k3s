@echo off
setlocal enabledelayedexpansion

:: Versions
set VBOX_VER=7.2.4
set HELM_VER=4.0.1
set KUBECTL_VER=1.34.0
set UBUNTU_VER=24.04

:: Filenames
set VBOX_FILE=VirtualBox-%VBOX_VER%-170995-Win.exe
set HELM_FILE=helm-v%HELM_VER%-windows-amd64.zip
set KUBECTL_FILE=kubectl.exe
set UBUNTU_FILE=ubuntu-%UBUNTU_VER%-server-cloudimg-amd64.vmdk

:: Download binaries and checksum files
curl.exe -LO "https://download.virtualbox.org/virtualbox/%VBOX_VER%/%VBOX_FILE%"
curl.exe -LO "https://download.virtualbox.org/virtualbox/%VBOX_VER%/SHA256SUMS"
rename SHA256SUMS SHA256SUMS.virtualbox

curl.exe -LO "https://get.helm.sh/%HELM_FILE%"
curl.exe -LO "https://get.helm.sh/%HELM_FILE%.sha256sum"

curl.exe -LO "https://dl.k8s.io/release/v%KUBECTL_VER%/bin/windows/amd64/%KUBECTL_FILE%"
curl.exe -LO "https://dl.k8s.io/v%KUBECTL_VER%/bin/windows/amd64/%KUBECTL_FILE%.sha256"
:: Normalize kubectl checksum file
for /f %%h in (%KUBECTL_FILE%.sha256) do (
    echo %%h kubectl.exe > %KUBECTL_FILE%.sha256
)

curl.exe -LO "https://cloud-images.ubuntu.com/releases/noble/release/%UBUNTU_FILE%"
curl.exe -LO "https://cloud-images.ubuntu.com/releases/noble/release/SHA256SUMS"
rename SHA256SUMS SHA256SUMS.ubuntu

:: Merge all checksum files into one
copy /b SHA256SUMS.virtualbox + %HELM_FILE%.sha256sum + SHA256SUMS.ubuntu + %KUBECTL_FILE%.sha256 SHA256SUMS

echo.
echo All checksums merged into SHA256SUMS
echo.

set VERIFIED=1

:: Verify each file
for %%f in (%VBOX_FILE% %HELM_FILE% %KUBECTL_FILE% %UBUNTU_FILE%) do (
    echo Checking %%f ...
    set EXPECTED=
    set ACTUAL=
    for /f "tokens=1" %%h in ('findstr /i "%%f" SHA256SUMS') do set EXPECTED=%%h
    for /f "tokens=*" %%h in ('CertUtil -hashfile %%f SHA256 ^| findstr /r /v "hash CertUtil"') do set ACTUAL=%%h
    echo Expected: !EXPECTED!
    echo Actual:   !ACTUAL!
    if /i "!EXPECTED!"=="!ACTUAL!" (
        echo Match OK
    ) else (
        echo MISMATCH!
        set VERIFIED=0
    )
    echo.
)

:: If verification passed, proceed with install/unpack
if !VERIFIED! == 1 (
    echo All files verified successfully.
    echo Extracting Helm...
    tar.exe -xf %HELM_FILE%
    echo Installing VirtualBox silently...
    %VBOX_FILE% --silent --ignore-reboot
) else (
    echo Verification failed. Aborting installation.
)

echo.
echo Process complete.
pause