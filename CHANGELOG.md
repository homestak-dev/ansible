# Changelog

## Unreleased

### Phase 5: ConfigResolver Support

- Add iac-driver sync to nested-pve role for recursive ConfigResolver deployment

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
