#!/bin/bash
#
# Proxmox PVE Bootstrap Script
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

echo "==> Proxmox PVE Post-Install Setup"
echo "==> Target user: $USERNAME"

# Create local user if not exists
if id "$USERNAME" &>/dev/null; then
    echo "==> User '$USERNAME' already exists, skipping"
else
    echo "==> Creating user '$USERNAME'"
    useradd -m -s /bin/bash "$USERNAME"
fi

# Add user to sudo group
if groups "$USERNAME" | grep -q '\bsudo\b'; then
    echo "==> User '$USERNAME' already in sudo group"
else
    echo "==> Adding '$USERNAME' to sudo group"
    usermod -aG sudo "$USERNAME"
fi

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
apt install -y ansible git python3-pip

echo ""
echo "==> Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Set password: passwd $USERNAME"
echo "  2. Log in as '$USERNAME'"
echo "  3. cd /opt/proxmox-pve"
if [[ "$USERNAME" == "$DEFAULT_USER" ]]; then
    echo "  4. Run: ansible-playbook -i inventory/local.yml playbooks/site.yml"
else
    echo "  4. Run: ansible-playbook -i inventory/local.yml playbooks/site.yml -e local_user=$USERNAME"
fi
echo ""
