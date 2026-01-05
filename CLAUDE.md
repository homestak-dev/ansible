# Ansible - Ansible Configuration for Proxmox

Ansible playbooks for configuring fresh Proxmox VE installations and installing PVE on Debian.

## Quick Reference

```bash
# Post-install configuration (local via iac-driver)
cd ../iac-driver && ./run.sh --scenario pve-configure --local

# Post-install configuration (remote via iac-driver)
cd ../iac-driver && ./run.sh --scenario pve-configure --remote <IP>

# Or run playbooks directly:
ansible-playbook -i inventory/local.yml playbooks/pve-setup.yml
ansible-playbook -i inventory/local.yml playbooks/user.yml

# Install PVE on Debian 13 Trixie
ansible-playbook -i inventory/remote-dev.yml playbooks/pve-install.yml \
  -e ansible_host=<IP> -e pve_hostname=<hostname>
```

## Project Structure

```
ansible/
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
│   ├── pve-setup.yml     # Core PVE config
│   ├── pve-install.yml   # Install PVE on Debian 13 Trixie
│   ├── pve-network.yml   # Network config (re-IP, rename, IPv6)
│   ├── trigger-network.yml # Push-triggers-pull for network changes
│   ├── pve-iac-setup.yml # Install IaC tools (packer, tofu)
│   ├── nested-pve-setup.yml  # E2E test: configure inner PVE
│   └── user.yml          # User management only
└── roles/
    ├── base/             # System packages, timezone, locale
    ├── users/            # Create local_user with sudo
    ├── security/         # SSH hardening, fail2ban (prod)
    ├── proxmox/          # PVE-specific config (repos, certs)
    ├── pve-install/      # Install PVE on Debian 13
    ├── pve-network/      # Network: re-IP, rename, DHCP/static, IPv6
    ├── pve-iac/          # Generic: install packer, tofu, API token
    └── nested-pve/       # E2E: network bridge, SSH keys, copy files
```

## Installation

See [homestak-dev/bootstrap](https://github.com/homestak-dev/bootstrap) for the recommended installation method:

```bash
# One-command setup
curl -fsSL https://raw.githubusercontent.com/homestak-dev/bootstrap/master/install.sh | bash

# After bootstrap, use the 'homestak' command
homestak pve-setup
homestak user -e local_user=myuser
homestak network -e pve_network_tasks='["static"]' -e pve_new_ip=10.0.12.100
```

### Manual (without bootstrap)
```bash
git clone https://github.com/homestak-dev/ansible.git /opt/ansible
cd /opt/ansible
apt install -y ansible git
ansible-playbook -i inventory/local.yml playbooks/pve-setup.yml -c local
```

## Execution Models

### Push Model (traditional)
Remote controller SSHs to target and runs playbooks:
```bash
ansible-playbook -i inventory/remote-dev.yml playbooks/pve-network.yml \
  -e ansible_host=10.0.12.62 -e ansible_user=root ...
```
**Limitation**: SSH connection breaks when IP changes.

### Push-Triggers-Pull Model (for network changes)
Controller triggers local execution on target, avoiding SSH issues:
```bash
ansible-playbook -i inventory/remote-dev.yml playbooks/trigger-network.yml \
  -e ansible_host=10.0.12.62 \
  -e pve_network_tasks='["reip","reboot"]' \
  -e pve_new_ip=10.0.12.100 \
  -e pve_new_gateway=10.0.12.1
```
**How it works**:
1. Pushes vars to target
2. Triggers local ansible-playbook execution (async)
3. Target applies changes and reboots itself
4. Controller waits for new IP, verifies success

### Local Model (on-host)
Run directly on the PVE host:
```bash
/opt/homestak/run-local.sh network \
  -e pve_network_tasks='["reip","reboot"]' \
  -e pve_new_ip=10.0.12.100
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
| [bootstrap](https://github.com/homestak-dev/bootstrap) | Entry point - curl\|bash setup |
| [site-config](https://github.com/homestak-dev/site-config) | Site-specific secrets and configuration |
| [ansible](https://github.com/homestak-dev/ansible) | This project - Proxmox configuration |
| [iac-driver](https://github.com/homestak-dev/iac-driver) | Orchestration engine |
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

**nested-pve role tasks:**
- `network.yml` - Configure vmbr0 bridge for VM networking
- `ssh-keys.yml` - Copy SSH keys for nested VM access
- `copy-files.yml` - Sync homestak repos, enable snippets on local datastore, fix SSL certs (IPv6 workaround), create API token

See `../iac-driver/CLAUDE.md` for full E2E procedure and architecture.

## Community Role Adoption (Planned)

See [GitHub Issue #8](https://github.com/homestak-dev/ansible/issues/8) for the full plan.

### lae.proxmox (Validated)

Tested successfully on Debian 13 Trixie. Can replace `roles/pve-install` and `roles/proxmox`:

```bash
# Install role
ansible-galaxy role install lae.proxmox

# Test playbook
ansible-playbook -i '10.0.12.x,' playbooks/test-lae-proxmox.yml -u root
```

**Requirements:** Ansible 2.15+ (for `deb822_repository` module)

**Features:** PVE installation, clustering, storage backends, subscription nag removal, Ceph, ZFS

### DebOps (Not Recommended)

Evaluated but **not suitable** for homestak:
- Requires Ansible 2.15+ (Debian ships 2.14)
- Framework, not standalone roles - depends on custom plugins, 60+ global handlers
- All-or-nothing adoption required
- Overkill for homelab use case

**Conclusion:** Keep current simple roles (base, users, security). They work with Debian's packaged Ansible and have no external dependencies.

### Planned Structure

```
collections/
├── homestak/
│   ├── debian/        # Debian-generic roles (base, users, security, networking)
│   └── proxmox/       # PVE-specific roles (install, configure, api_token)
└── requirements.yml   # lae.proxmox, community.proxmox
```

## GitHub Repository

- https://github.com/homestak-dev/ansible

## License

Apache 2.0 - see [LICENSE](LICENSE)
