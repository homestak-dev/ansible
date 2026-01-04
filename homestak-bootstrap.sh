#!/bin/bash
#
# Homestak Bootstrap Script
# Sets up a Proxmox host for local IAC execution
#
# Usage (curl|bash):
#   curl -fsSL https://raw.githubusercontent.com/homestak-dev/ansible/master/homestak-bootstrap.sh | bash
#
# Usage (local):
#   ./homestak-bootstrap.sh [--apply <task>] [--vars <vars-file>]
#
# Options:
#   --apply <task>    Run a task after bootstrap (pve-setup, user, network)
#   --vars <file>     JSON/YAML vars file for the task
#   --help            Show this help
#
set -euo pipefail

# Configuration
HOMESTAK_DIR="/opt/homestak"
ANSIBLE_REPO="https://github.com/homestak-dev/ansible.git"
BRANCH="${HOMESTAK_BRANCH:-master}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}==>${NC} $1"; }
log_warn() { echo -e "${YELLOW}==>${NC} $1"; }
log_error() { echo -e "${RED}==>${NC} $1"; }

usage() {
    cat <<EOF
Homestak Bootstrap Script

Usage: $0 [options]

Options:
    --apply <task>    Run a task after bootstrap
                      Tasks: pve-setup, user, network
    --vars <file>     JSON/YAML vars file for the task
    --branch <branch> Git branch to use (default: master)
    --help            Show this help

Examples:
    # Bootstrap only
    curl -fsSL https://raw.githubusercontent.com/homestak-dev/ansible/master/homestak-bootstrap.sh | bash

    # Bootstrap and configure PVE
    ./homestak-bootstrap.sh --apply pve-setup

    # Bootstrap and apply network changes
    ./homestak-bootstrap.sh --apply network --vars /tmp/network-vars.yml

EOF
    exit 0
}

# Parse arguments
APPLY_TASK=""
VARS_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --apply) APPLY_TASK="$2"; shift 2 ;;
        --vars) VARS_FILE="$2"; shift 2 ;;
        --branch) BRANCH="$2"; shift 2 ;;
        --help) usage ;;
        *) log_error "Unknown option: $1"; usage ;;
    esac
done

# Must run as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

log_info "Homestak Bootstrap"
log_info "Branch: $BRANCH"

#
# Step 1: Configure Proxmox repositories
#
log_info "Configuring Proxmox repositories..."

# Disable enterprise repos
for repo in /etc/apt/sources.list.d/{pve-enterprise.sources,ceph.sources}; do
    if [[ -f "$repo" ]]; then
        mv "$repo" "${repo}.disabled"
        log_info "  Disabled: $(basename $repo)"
    fi
done

# Add no-subscription repo
NOSUB_REPO="/etc/apt/sources.list.d/pve-no-subscription.list"
if [[ ! -f "$NOSUB_REPO" ]]; then
    CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
    echo "deb http://download.proxmox.com/debian/pve ${CODENAME} pve-no-subscription" > "$NOSUB_REPO"
    log_info "  Added: pve-no-subscription repo"
fi

#
# Step 2: Install prerequisites
#
log_info "Installing prerequisites..."
apt-get update -qq
apt-get install -y -qq git ansible python3-pip sudo > /dev/null

#
# Step 3: Clone/update homestak repos
#
log_info "Setting up homestak repositories..."

mkdir -p "$HOMESTAK_DIR"

clone_or_update() {
    local repo_url="$1"
    local target_dir="$2"
    local repo_name=$(basename "$target_dir")

    if [[ -d "$target_dir/.git" ]]; then
        log_info "  Updating $repo_name..."
        git -C "$target_dir" fetch -q
        git -C "$target_dir" checkout -q "$BRANCH" 2>/dev/null || git -C "$target_dir" checkout -q "origin/$BRANCH"
        git -C "$target_dir" pull -q origin "$BRANCH" 2>/dev/null || true
    else
        [[ -d "$target_dir" ]] && rm -rf "$target_dir"
        log_info "  Cloning $repo_name..."
        git clone -q -b "$BRANCH" "$repo_url" "$target_dir" 2>/dev/null || \
            git clone -q "$repo_url" "$target_dir"
    fi
}

clone_or_update "$ANSIBLE_REPO" "$HOMESTAK_DIR/ansible"

# Create symlink for backward compatibility
[[ -L /opt/ansible ]] || ln -sf "$HOMESTAK_DIR/ansible" /opt/ansible

#
# Step 4: Create local execution wrapper
#
log_info "Creating local execution wrapper..."

cat > "$HOMESTAK_DIR/run-local.sh" << 'WRAPPER'
#!/bin/bash
#
# Run ansible playbooks locally
#
set -euo pipefail

ANSIBLE_DIR="/opt/homestak/ansible"
INVENTORY="$ANSIBLE_DIR/inventory/local.yml"

usage() {
    echo "Usage: $0 <playbook> [-e extra_vars...]"
    echo ""
    echo "Playbooks:"
    echo "  pve-setup      Core PVE configuration"
    echo "  user           User management"
    echo "  network        Network configuration (requires -e vars)"
    echo ""
    echo "Examples:"
    echo "  $0 pve-setup"
    echo "  $0 network -e pve_network_tasks='[\"reip\",\"reboot\"]' -e pve_new_ip=10.0.12.100"
    exit 1
}

[[ $# -lt 1 ]] && usage

PLAYBOOK="$1"
shift

case "$PLAYBOOK" in
    pve-setup) PLAYBOOK_FILE="$ANSIBLE_DIR/playbooks/pve-setup.yml" ;;
    user) PLAYBOOK_FILE="$ANSIBLE_DIR/playbooks/user.yml" ;;
    network) PLAYBOOK_FILE="$ANSIBLE_DIR/playbooks/pve-network.yml" ;;
    *)
        if [[ -f "$PLAYBOOK" ]]; then
            PLAYBOOK_FILE="$PLAYBOOK"
        else
            echo "Unknown playbook: $PLAYBOOK"
            usage
        fi
        ;;
esac

echo "==> Running: $PLAYBOOK_FILE"
cd "$ANSIBLE_DIR"
ansible-playbook -i "$INVENTORY" "$PLAYBOOK_FILE" -c local "$@"
WRAPPER

chmod +x "$HOMESTAK_DIR/run-local.sh"

#
# Step 5: Apply task if requested
#
if [[ -n "$APPLY_TASK" ]]; then
    log_info "Applying task: $APPLY_TASK"

    EXTRA_VARS=""
    [[ -n "$VARS_FILE" ]] && EXTRA_VARS="-e @$VARS_FILE"

    case "$APPLY_TASK" in
        pve-setup)
            "$HOMESTAK_DIR/run-local.sh" pve-setup $EXTRA_VARS
            ;;
        user)
            "$HOMESTAK_DIR/run-local.sh" user $EXTRA_VARS
            ;;
        network)
            if [[ -z "$VARS_FILE" ]]; then
                log_error "Network task requires --vars <file>"
                exit 1
            fi
            "$HOMESTAK_DIR/run-local.sh" network $EXTRA_VARS
            ;;
        *)
            log_error "Unknown task: $APPLY_TASK"
            exit 1
            ;;
    esac
fi

#
# Done
#
log_info "Bootstrap complete!"
echo ""
echo "Homestak installed to: $HOMESTAK_DIR"
echo ""
echo "Run playbooks locally:"
echo "  /opt/homestak/run-local.sh pve-setup"
echo "  /opt/homestak/run-local.sh user -e local_user=myuser"
echo "  /opt/homestak/run-local.sh network -e @/path/to/vars.yml"
echo ""
