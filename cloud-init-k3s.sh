#!/bin/bash

# Requirement
TOOLS=("mkpasswd" "genisoimage")

for tool in "${TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        sudo apt update
        case "$tool" in
            mkpasswd)
                sudo apt install -y whois
                ;;
            genisoimage)
                sudo apt install -y genisoimage
                ;;
        esac
    fi
done

# Prompts
read -p "Enter password for k3s user: " PLAINTEXT_PASS
read -p "Enter number of master nodes: " MASTER_COUNT
read -p "Enter number of worker nodes: " WORKER_COUNT

BASE_IP=""
while [ -z "$BASE_IP" ]; do
    read -p "Enter starting IP (e.g. 192.168.31.134): " BASE_IP
    if [ -z "$BASE_IP" ]; then
        echo "IP cannot be empty. Please try again."
    fi
done

# Generate secrets
HASHED_PASS=$(mkpasswd -m sha-512 "$PLAINTEXT_PASS")
K3S_TOKEN=$(openssl rand -hex 32)

# Function to increment IP
function ip_incr() {
    local ip=$1
    local inc=$2
    IFS=. read -r i1 i2 i3 i4 <<< "$ip"
    echo "$i1.$i2.$i3.$((i4+inc))"
}

# Master Nodes
for i in $(seq 1 $MASTER_COUNT); do
    HOSTNAME="k3s-master-$(printf "%02d" $i)"
    FQDN="$HOSTNAME.demo.local"
    NODE_NAME="$HOSTNAME"
    NODE_IP=$(ip_incr $BASE_IP $((i-1)))

    mkdir -p "./$HOSTNAME"

    if [ $i -eq 1 ]; then
        cat > "./$HOSTNAME/user-data" <<EOF
#cloud-config
hostname: $HOSTNAME
fqdn: $FQDN
manage_etc_hosts: true
users:
  - name: k3s
    passwd: "$HASHED_PASS"
    lock_passwd: false
    groups: [sudo]
    shell: /bin/bash
write_files:
  - path: /root/bootstrap.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" K3S_KUBECONFIG_MODE="644" K3S_TOKEN="$K3S_TOKEN" sh -s - --cluster-init --write-kubeconfig-mode=644 --node-name=$NODE_NAME
runcmd:
  - /root/bootstrap.sh
EOF
    else
        cat > "./$HOSTNAME/user-data" <<EOF
#cloud-config
hostname: $HOSTNAME
fqdn: $FQDN
manage_etc_hosts: true
users:
  - name: k3s
    passwd: "$HASHED_PASS"
    lock_passwd: false
    groups: [sudo]
    shell: /bin/bash
write_files:
  - path: /root/bootstrap.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" K3S_URL=https://$BASE_IP:6443 K3S_TOKEN="$K3S_TOKEN" sh -s - --write-kubeconfig-mode=644 --node-name=$NODE_NAME
runcmd:
  - /root/bootstrap.sh
EOF
    fi

    cat > "./$HOSTNAME/meta-data" <<EOF
instance-id: $HOSTNAME
EOF

    genisoimage -output "./$HOSTNAME/cloud-init.iso" -volid cidata -joliet -rock "./$HOSTNAME/user-data" "./$HOSTNAME/meta-data"
done

# Worker Nodes
for i in $(seq 1 $WORKER_COUNT); do
    HOSTNAME="k3s-worker-$(printf "%02d" $i)"
    FQDN="$HOSTNAME.demo.local"
    NODE_NAME="$HOSTNAME"
    NODE_IP=$(ip_incr $BASE_IP $((MASTER_COUNT+i-1)))

    mkdir -p "./$HOSTNAME"

    cat > "./$HOSTNAME/user-data" <<EOF
#cloud-config
hostname: $HOSTNAME
fqdn: $FQDN
manage_etc_hosts: true
users:
  - name: k3s
    passwd: "$HASHED_PASS"
    lock_passwd: false
    groups: [sudo]
    shell: /bin/bash
write_files:
  - path: /root/bootstrap.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      curl -sfL https://get.k3s.io | K3S_URL=https://$BASE_IP:6443 K3S_TOKEN="$K3S_TOKEN" sh -s - --node-name=$NODE_NAME
runcmd:
  - /root/bootstrap.sh
EOF

    cat > "./$HOSTNAME/meta-data" <<EOF
instance-id: $HOSTNAME
EOF

    genisoimage -output "./$HOSTNAME/cloud-init.iso" -volid cidata -joliet -rock "./$HOSTNAME/user-data" "./$HOSTNAME/meta-data"
done

echo "Configs and ISOs generated for $MASTER_COUNT masters and $WORKER_COUNT workers."
echo "Password for user k3s is: $PLAINTEXT_PASS"