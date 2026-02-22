# homestak.proxmox

Proxmox VE installation and configuration roles.

## Roles

| Role | Purpose |
|------|---------|
| `install` | Install PVE on Debian 13 Trixie |
| `configure` | PVE config (repos, subscription nag removal) |
| `networking` | Re-IP, rename, DHCP/static, IPv6, vmbr0 bridges |
| `api_token` | Create pveum API token for tofu |

## Usage

```yaml
- hosts: proxmox
  roles:
    - homestak.debian.base
    - homestak.debian.security
    - homestak.proxmox.configure
```

## Requirements

- Ansible 2.15+
- `homestak.debian` collection (dependency)
- Debian 13 (Trixie) for fresh PVE installation

## Variables

### install role

| Variable | Default | Description |
|----------|---------|-------------|
| `pve_hostname` | (required) | Hostname for PVE node |

### networking role

| Variable | Default | Description |
|----------|---------|-------------|
| `pve_network_tasks` | [] | Tasks to run: reip, rename, dhcp, static, ipv6, reboot |
| `pve_new_ip` | "" | New IP address |
| `pve_new_gateway` | "" | New gateway |
| `pve_network_interface` | vmbr0 | Network interface to configure |

### api_token role

Creates `root@pam!tofu` API token for OpenTofu automation.

## Dependencies

This collection depends on `homestak.debian` (specified in `galaxy.yml`).

## License

Apache 2.0
