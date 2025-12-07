#!/bin/bash
set -euo pipefail

# Versions
VBOX_VER="7.2.4"
HELM_VER="4.0.1"
KUBECTL_VER="1.34.0"
UBUNTU_VER="24.04"

# Filenames
VBOX_RUN="VirtualBox-${VBOX_VER}-170995-Linux_amd64.run"
HELM_FILE="helm-v${HELM_VER}-linux-amd64.tar.gz"
KUBECTL_FILE="kubectl"
UBUNTU_FILE="ubuntu-${UBUNTU_VER}-server-cloudimg-amd64.vmdk"

# Ensure required tools are installed
sudo apt update
sudo apt install -y curl tar coreutils build-essential dkms linux-headers-$(uname -r)

# Download binaries and checksum files
curl -LO "https://download.virtualbox.org/virtualbox/${VBOX_VER}/${VBOX_RUN}"
curl -LO "https://download.virtualbox.org/virtualbox/${VBOX_VER}/SHA256SUMS"
mv SHA256SUMS SHA256SUMS.virtualbox

curl -LO "https://get.helm.sh/${HELM_FILE}"
curl -LO "https://get.helm.sh/${HELM_FILE}.sha256sum"

curl -LO " /release/v${KUBECTL_VER}/bin/linux/amd64/${KUBECTL_FILE}"
curl -LO "https://dl.k8s.io/v${KUBECTL_VER}/bin/windows/amd64/${KUBECTL_FILE}.sha256"

curl -LO "https://cloud-images.ubuntu.com/releases/noble/release/${UBUNTU_FILE}"
curl -LO "https://cloud-images.ubuntu.com/releases/noble/release/SHA256SUMS"
mv SHA256SUMS SHA256SUMS.ubuntu

# Merge all checksum files into one
cat SHA256SUMS.virtualbox "${HELM_FILE}.sha256sum" "${KUBECTL_FILE}.sha256" SHA256SUMS.ubuntu > SHA256SUMS

echo "All checksums merged into SHA256SUMS"
echo

VERIFIED=1

# Verify each file
for f in "$VBOX_RUN" "$HELM_FILE" "$KUBECTL_FILE" "$UBUNTU_FILE"; do
    echo "Checking $f ..."
    EXPECTED=$(grep -i "$f" SHA256SUMS | awk '{print $1}')
    ACTUAL=$(sha256sum "$f" | awk '{print $1}')
    echo "Expected: $EXPECTED"
    echo "Actual:   $ACTUAL"
    if [ "$EXPECTED" = "$ACTUAL" ]; then
        echo "Match OK"
    else
        echo "MISMATCH!"
        VERIFIED=0
    fi
    echo
done

# If verification passed, proceed with install/unpack
if [ "$VERIFIED" -eq 1 ]; then
    echo "All files verified successfully."
    echo "Extracting Helm..."
    tar -xzf "$HELM_FILE"
    echo "Installing VirtualBox with .run installer..."
    chmod +x "$VBOX_RUN"
    sudo "./$VBOX_RUN" install
    echo "Adding current user to vboxusers group..."
    sudo usermod -a -G vboxusers "$USER"
    echo "You may need to log out and back in for group changes to take effect."
else
    echo "Verification failed. Aborting installation."
fi

echo "Process complete."