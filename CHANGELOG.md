# Changelog

## Unreleased

### Collection Split (#9)

Reorganized roles into two Ansible collections for better separation of concerns:

**homestak.debian** - Debian-generic roles:
- `base` - System packages, timezone, locale
- `users` - User creation with sudo
- `security` - SSH hardening, fail2ban
- `iac_tools` - Install packer and tofu (extracted from pve-iac)

**homestak.proxmox** - PVE-specific roles:
- `install` - Install PVE on Debian 13 (from pve-install)
- `configure` - PVE config, nag removal (from proxmox)
- `networking` - Re-IP, rename, DHCP/static, IPv6 (from pve-network)
- `api_token` - Create pveum API token (extracted from pve-iac)
- `nested` - E2E testing setup (from nested-pve)

**Breaking Changes:**
- Playbooks now use FQCN role references (e.g., `homestak.debian.base`)
- Legacy `roles/` directory deprecated
- `ansible.cfg` updated with `collections_path`

### Ansible 2.15+ Migration

- Makefile: Install Ansible via pipx (2.15+) instead of apt
- Required for `deb822_repository` module used by lae.proxmox

### Community Role Evaluation (#8)

- **lae.proxmox v1.10.0**: Successfully tested on Debian 13 Trixie
  - Installs PVE, removes subscription nag, configures repositories
  - Requires Ansible 2.15+ for `deb822_repository` module
- **DebOps**: Evaluated, not recommended (framework complexity)
- Add `playbooks/test-lae-proxmox.yml` for community role testing

### Phase 5: ConfigResolver Support

- Add iac-driver sync to nested-pve role for recursive ConfigResolver deployment
- Rename `pve-deb` to `nested-pve` in copy-files task (aligns with site-config)

## v0.5.0-rc1 - 2026-01-04

Consolidated pre-release with network configuration.

### Highlights

- pve-install role for Debian 13 → PVE conversion
- pve-network role with reip, rename, dhcp, static, ipv6
- E2E tested via nested-pve-roundtrip

### Features

- Add `pve-network` role for network configuration tasks:
  - `reip` - Change static IP address
  - `rename` - Change hostname and FQDN
  - `dhcp` - Convert interface to DHCP
  - `static` - Convert interface to static IP
  - `ipv6` - Enable/disable IPv6
  - `reboot` - Reboot and wait for reconnection (handles IP changes)
- Add `pve-network.yml` playbook (push model)
- Add `trigger-network.yml` playbook (push-triggers-pull model)

### Changes

- Remove `site.yml` - combo logic moved to iac-driver `pve-configure` scenario
- Remove `install.sh`, `bootstrap.sh` - moved to [bootstrap](https://github.com/homestak-dev/bootstrap) repo
- Fix pve-install GPG key download for Debian 13 (use curl instead of get_url)
- Update docs to reference bootstrap repo and `pve-configure` scenario

## v0.1.0-rc1 - 2026-01-03

### Roles

- **pve-install**: Debian 13 to Proxmox VE installation
- **pve-iac**: IaC tooling (packer, tofu, API tokens)
- **nested-pve**: E2E test configuration (network, SSH keys, file deployment)
- **base**: Common system configuration
- **users**: User management
- **security**: Security hardening
- **proxmox**: Proxmox host configuration

### Infrastructure

- Branch protection enabled (PR reviews for non-admins)
- Tested via iac-driver nested-pve-roundtrip scenario
