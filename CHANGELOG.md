# Changelog

## Unreleased

### Features

- Add `pve-network` role for network configuration tasks:
  - `reip` - Change static IP address
  - `rename` - Change hostname and FQDN
  - `dhcp` - Convert interface to DHCP
  - `static` - Convert interface to static IP
  - `ipv6` - Enable/disable IPv6
  - `reboot` - Reboot and wait for reconnection
- Add `pve-network.yml` playbook

### Changes

- Remove `site.yml` - combo logic moved to iac-driver `pve-configure` scenario
- Update docs to reference `pve-configure` scenario or running playbooks directly

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
