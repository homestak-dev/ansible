#!/bin/bash
#
# Proxmox PVE Post-Install Setup
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/john-derose/proxmox-pve/master/install.sh | bash
#
# Custom username:
#   curl -sSL https://raw.githubusercontent.com/john-derose/proxmox-pve/master/install.sh | NEWUSER=myuser bash
#
set -euo pipefail

REPO_URL="https://github.com/john-derose/proxmox-pve.git"
INSTALL_DIR="/opt/proxmox-pve"
NEWUSER="${NEWUSER:-sysadm}"

# Must run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root"
    echo "Usage: curl -sSL https://raw.githubusercontent.com/john-derose/proxmox-pve/master/install.sh | sudo bash"
    exit 1
fi

echo "==> Proxmox PVE Post-Install Setup"
echo "==> Target user: $NEWUSER"

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
