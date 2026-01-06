# homestak.debian

Debian-generic Ansible roles for system configuration.

## Roles

| Role | Purpose |
|------|---------|
| `base` | System packages, timezone, locale configuration |
| `users` | Create local user with sudo access |
| `security` | SSH hardening, fail2ban (production) |
| `iac_tools` | Install packer and tofu from official repos |

## Usage

```yaml
- hosts: all
  roles:
    - homestak.debian.base
    - homestak.debian.users
    - homestak.debian.security
```

## Requirements

- Ansible 2.15+ (for `deb822_repository` module compatibility)
- Debian 12 (Bookworm) or Debian 13 (Trixie)

## Variables

### users role

| Variable | Default | Description |
|----------|---------|-------------|
| `local_user` | sysadm | Non-root user to create |
| `sudo_nopasswd` | false | Allow passwordless sudo |

### security role

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_permit_root_login` | prohibit-password | SSH root login policy |
| `ssh_password_auth` | no | Allow password authentication |

## License

Apache 2.0
