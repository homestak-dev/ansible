# Proxmox PVE Post-Install Setup

Ansible playbooks for configuring fresh Proxmox VE installations.

## Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/john-derose/proxmox-pve/master/install.sh | bash
```

Custom username (default: `sysadm`):

```bash
curl -sSL https://raw.githubusercontent.com/john-derose/proxmox-pve/master/install.sh | NEWUSER=myuser bash
```

## After Install

Log in as the new user and run:

```bash
cd /opt/proxmox-pve
ansible-playbook -i inventory/local.yml playbooks/site.yml -e local_user=$USER
```

## Inventory Options

| Inventory | Connection | Use case |
|-----------|------------|----------|
| `local.yml` | local | Running on the host you're configuring |
| `local-dev.yml` | local | Local with dev tools (strace, tcpdump) |
| `remote-dev.yml` | SSH | Remote dev/test hosts |
| `remote-prod.yml` | SSH | Remote production (strict SSH, fail2ban) |

## What It Does

- Creates non-privileged user with sudo
- Disables enterprise repos, enables no-subscription repo
- Installs common packages (htop, git, vim, tmux, etc.)
- Configures SSH hardening
- Removes subscription nag from web UI

## Structure

```
inventory/       # Host definitions (local, remote-dev, remote-prod)
group_vars/      # Environment-specific variables
roles/           # base, users, security, proxmox
```
