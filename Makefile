# ansible Makefile
# Dependency installation and setup

.PHONY: help install-deps check

# Minimum Ansible version required (for deb822_repository module, lae.proxmox)
ANSIBLE_MIN_VERSION := 2.15

help:
	@echo "Ansible Setup"
	@echo ""
	@echo "  make install-deps  - Install Ansible via pipx (2.15+)"
	@echo "  make check         - Verify installation"
	@echo ""

install-deps:
	@echo "Installing ansible dependencies..."
	@apt-get update -qq
	@apt-get install -y -qq python3 python3-pip python3-venv pipx git sudo > /dev/null
	@echo "Installing ansible-core via pipx..."
	@PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install ansible-core --include-deps
	@echo "Done. Ansible installed to /usr/local/bin/ansible"

check:
	@echo "Checking ansible installation..."
	@echo ""
	@printf "  python3: " && (which python3 >/dev/null 2>&1 && python3 --version || echo "NOT INSTALLED")
	@printf "  ansible: " && (which ansible >/dev/null 2>&1 && ansible --version | head -1 || echo "NOT INSTALLED")
	@printf "  git:     " && (which git >/dev/null 2>&1 && git --version || echo "NOT INSTALLED")
	@echo ""
	@# Version check
	@if which ansible >/dev/null 2>&1; then \
		ver=$$(ansible --version | head -1 | grep -oP '\d+\.\d+' | head -1); \
		if [ "$$(printf '%s\n' "$(ANSIBLE_MIN_VERSION)" "$$ver" | sort -V | head -1)" = "$(ANSIBLE_MIN_VERSION)" ]; then \
			echo "  ✓ Ansible $$ver meets minimum $(ANSIBLE_MIN_VERSION)"; \
		else \
			echo "  ✗ Ansible $$ver < $(ANSIBLE_MIN_VERSION) - run 'make install-deps'"; \
		fi \
	fi
