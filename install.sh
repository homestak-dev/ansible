#!/bin/bash
#
# Proxmox Post-Install Setup
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/JDeRose-net/ansible/master/install.sh | bash
#
# Custom username:
#   curl -sSL https://raw.githubusercontent.com/JDeRose-net/ansible/master/install.sh | NEWUSER=myuser bash
#
set -euo pipefail

REPO_URL="https://github.com/JDeRose-net/ansible.git"
INSTALL_DIR="/opt/ansible"
NEWUSER="${NEWUSER:-sysadm}"

# Must run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root"
    echo "Usage: curl -sSL https://raw.githubusercontent.com/JDeRose-net/ansible/master/install.sh | sudo bash"
    exit 1
fi

echo "==> Proxmox Post-Install Setup"
echo "==> Target user: $NEWUSER"

# Disable enterprise repos (they block apt update without subscription)
echo "==> Configuring repositories..."
for repo in /etc/apt/sources.list.d/{pve-enterprise.sources,ceph.sources}; do
    if [[ -f "$repo" ]]; then
        mv "$repo" "${repo}.disabled"
        echo "    Disabled: $repo"
    fi
done

# Add no-subscription repo if not present
NOSUB_REPO="/etc/apt/sources.list.d/pve-no-subscription.list"
if [[ ! -f "$NOSUB_REPO" ]]; then
    CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
    echo "deb http://download.proxmox.com/debian/pve ${CODENAME} pve-no-subscription" > "$NOSUB_REPO"
    echo "    Added: pve-no-subscription repo"
fi

# Install git if not present
if ! command -v git &>/dev/null; then
    echo "==> Installing git..."
    apt update && apt install -y git
fi

# Clone or update repo
if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "==> Updating existing installation..."
    git -C "$INSTALL_DIR" pull
else
    if [[ -d "$INSTALL_DIR" ]]; then
        echo "==> Removing existing directory..."
        rm -rf "$INSTALL_DIR"
    fi
    echo "==> Cloning repository to $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Set permissions - readable/executable by all, writable by root
chmod 755 "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/bootstrap.sh"

echo ""
echo "==> Running bootstrap..."
"$INSTALL_DIR/bootstrap.sh" -u "$NEWUSER"
