# ansible Makefile
# Dependency installation and setup

.PHONY: help install-deps check

help:
	@echo "Ansible Setup"
	@echo ""
	@echo "  make install-deps  - Install required system packages"
	@echo "  make check         - Verify installation"
	@echo ""

install-deps:
	@echo "Installing ansible dependencies..."
	@apt-get update -qq
	@apt-get install -y -qq python3 python3-pip ansible git sudo > /dev/null
	@echo "Done."

check:
	@echo "Checking ansible installation..."
	@echo ""
	@printf "  python3: " && (which python3 >/dev/null 2>&1 && python3 --version || echo "NOT INSTALLED")
	@printf "  ansible: " && (which ansible >/dev/null 2>&1 && ansible --version | head -1 || echo "NOT INSTALLED")
	@printf "  git:     " && (which git >/dev/null 2>&1 && git --version || echo "NOT INSTALLED")
	@echo ""
