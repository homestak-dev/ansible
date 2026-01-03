# Ansible - Ansible Configuration for Proxmox

Ansible playbooks for configuring fresh Proxmox VE installations and installing PVE on Debian.

## Quick Reference

```bash
# Post-install configuration (local)
ansible-playbook -i inventory/local.yml playbooks/site.yml

# Post-install configuration (remote)
ansible-playbook -i inventory/remote-dev.yml playbooks/pve-setup.yml \
  -e ansible_host=<IP>

# Install PVE on Debian 13 Trixie
ansible-playbook -i inventory/remote-dev.yml playbooks/pve-install.yml \
  -e ansible_host=<IP> -e pve_hostname=<hostname>

# User management only
ansible-playbook -i inventory/local.yml playbooks/user.yml
```

## Project Structure

```
ansible/
├── install.sh            # curl|bash entry point
├── bootstrap.sh          # Pre-ansible system prep
├── ansible.cfg           # Ansible configuration
├── inventory/
│   ├── local.yml         # Local execution (ansible_connection: local)
│   ├── local-dev.yml     # Local with dev group settings
│   ├── remote-dev.yml    # SSH to dev hosts (requires -e ansible_host=<IP>)
│   ├── remote-prod.yml   # SSH to prod hosts
│   └── group_vars/
│       ├── all.yml       # Common vars (local_user: sysadm)
│       ├── local.yml     # Permissive SSH, sudo_nopasswd: true
│       ├── dev.yml       # Dev tools, sudo_nopasswd: true
│       └── prod.yml      # Strict SSH, fail2ban, sudo_nopasswd: false
├── playbooks/
│   ├── site.yml          # Full setup (pve-setup + user)
│   ├── pve-setup.yml     # Core PVE config
│   ├── pve-install.yml   # Install PVE on Debian 13 Trixie
│   ├── pve-iac-setup.yml # Install IaC tools (packer, tofu)
│   ├── nested-pve-setup.yml  # E2E test: configure inner PVE
│   └── user.yml          # User management only
└── roles/
    ├── base/             # System packages, timezone, locale
    ├── users/            # Create local_user with sudo
    ├── security/         # SSH hardening, fail2ban (prod)
    ├── proxmox/          # PVE-specific config (repos, certs)
    ├── pve-install/      # Install PVE on Debian 13
    ├── pve-iac/          # Generic: install packer, tofu, API token
    └── nested-pve/       # E2E: network bridge, SSH keys, copy files
```

## Installation Methods

### curl|bash (fresh Proxmox)
```bash
curl -fsSL https://raw.githubusercontent.com/homestak-dev/ansible/master/install.sh | NEWUSER=sysadm bash
```

### Manual
```bash
git clone https://github.com/homestak-dev/ansible.git /opt/ansible
cd /opt/ansible
./bootstrap.sh
ansible-playbook -i inventory/local.yml playbooks/site.yml
```

## Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `local_user` | sysadm | Non-root user to create |
| `sudo_nopasswd` | varies | Passwordless sudo (true for local/dev) |
| `ansible_host` | - | Required for remote inventories |
| `pve_hostname` | - | Required for pve-install playbook |

## Related Projects

Part of the [homestak-dev](https://github.com/homestak-dev) organization:

| Repo | Purpose |
|------|---------|
| [ansible](https://github.com/homestak-dev/ansible) | This project - Proxmox configuration |
| [iac-driver](https://github.com/homestak-dev/iac-driver) | E2E test orchestration |
| [packer](https://github.com/homestak-dev/packer) | Custom Debian cloud images |
| [tofu](https://github.com/homestak-dev/tofu) | VM provisioning with OpenTofu |

## Playbook Details

### pve-install.yml
Installs Proxmox VE on Debian 13 Trixie following the official wiki guide:
1. Configures hostname and /etc/hosts
2. Adds Proxmox repository (no-subscription)
3. Installs Proxmox kernel and reboots
4. Installs PVE packages (proxmox-ve, postfix, open-iscsi, chrony)
5. Removes Debian kernel packages
6. Cleans up temporary repo config

**Requirements:**
- Fresh Debian 13 (Trixie) installation
- SSH access as root
- Secure Boot disabled

### pve-setup.yml
Post-install configuration for existing PVE hosts:
- Base system packages
- SSH hardening (environment-specific)
- Proxmox repo configuration

### user.yml
Creates non-privileged sudoer user (local_user variable).

## E2E Testing Roles

| Role | Purpose |
|------|---------|
| `pve-iac` | Install packer/tofu, create API token (reusable) |
| `nested-pve` | Configure inner PVE for E2E tests (depends on pve-iac) |

See `../iac-driver/CLAUDE.md` for full E2E procedure and architecture.

## GitHub Repository

- https://github.com/homestak-dev/ansible

## License

Apache 2.0 - see [LICENSE](LICENSE)
