#!/bin/bash
#
# Proxmox Bootstrap Script
# Prepares a fresh Proxmox install for Ansible management
#
set -euo pipefail

DEFAULT_USER="sysadm"
REPO_FILE="/etc/apt/sources.list.d/pve-no-subscription.list"

usage() {
    echo "Usage: $0 [-u username]"
    echo ""
    echo "Options:"
    echo "  -u USERNAME   Local user to create (default: $DEFAULT_USER)"
    echo "  -h            Show this help message"
    exit 1
}

# Parse arguments
USERNAME="$DEFAULT_USER"
while getopts "u:h" opt; do
    case $opt in
        u) USERNAME="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Must run as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root"
    exit 1
fi

echo "==> Proxmox Post-Install Setup"
echo "==> Target user: $USERNAME"

# Disable enterprise repos
echo "==> Disabling enterprise repositories"
for repo in /etc/apt/sources.list.d/{pve-enterprise.sources,ceph.sources}; do
    if [[ -f "$repo" ]]; then
        mv "$repo" "${repo}.disabled"
        echo "    Disabled: $repo"
    fi
done

# Add no-subscription repo
if [[ -f "$REPO_FILE" ]]; then
    echo "==> No-subscription repo already configured"
else
    echo "==> Adding Proxmox no-subscription repository"
    # Detect Debian codename
    CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
    echo "deb http://download.proxmox.com/debian/pve ${CODENAME} pve-no-subscription" > "$REPO_FILE"
fi

# Update and install prerequisites
echo "==> Updating package lists"
apt update

echo "==> Installing Ansible and prerequisites"
apt install -y ansible git python3-pip sudo

echo ""
echo "==> Bootstrap complete!"
echo ""
echo "Next steps (as root):"
echo "  cd /opt/ansible"
echo "  ansible-playbook -i inventory/local.yml playbooks/pve-setup.yml"
echo "  ansible-playbook -i inventory/local.yml playbooks/user.yml -e local_user=$USERNAME"
echo "  passwd $USERNAME"
echo ""
