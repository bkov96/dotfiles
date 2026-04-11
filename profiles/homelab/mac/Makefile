.DEFAULT_GOAL := help

ADMIN_DIR := admin
OPS_DIR := ops
ADMIN_SETUP := $(ADMIN_DIR)/setup
OPS_SETUP := $(OPS_DIR)/setup
HEADLESS := $(ADMIN_SETUP)/headless

# --- Admin targets (run as admin, with display) ---

admin-init:
	@sh $(ADMIN_SETUP)/init.sh $(ADMIN_DIR)

admin-install:
	@sh $(ADMIN_SETUP)/install.sh $(ADMIN_DIR)

admin-configure:
	@sh $(ADMIN_SETUP)/configure.sh $(ADMIN_DIR)

admin-headless-user:
	@sh $(HEADLESS)/user.sh $(ADMIN_DIR)

admin-headless-ssh:
	@sh $(HEADLESS)/ssh.sh $(ADMIN_DIR)

admin-headless-energy:
	@sh $(HEADLESS)/energy.sh

admin-headless-firewall:
	@sh $(HEADLESS)/firewall.sh

admin-headless-screen-sharing:
	@sh $(HEADLESS)/screen-sharing.sh $(ADMIN_DIR)

admin-headless-all: admin-headless-user admin-headless-ssh admin-headless-energy admin-headless-firewall admin-headless-screen-sharing

admin-verify:
	@sh $(ADMIN_SETUP)/verify.sh $(ADMIN_DIR)

# --- Ops targets (run as ops, via SSH) ---

ops-init:
	@sh $(OPS_SETUP)/init.sh $(OPS_DIR)

ops-install:
	@sh $(OPS_SETUP)/install.sh $(OPS_DIR)

ops-disable-wifi:
	@sh $(OPS_SETUP)/disable-wifi.sh

ops-verify:
	@sh $(OPS_SETUP)/verify.sh $(OPS_DIR)

# --- Help ---

help:
	@echo ""
	@echo "  Homelab Mac Mini Bootstrap"
	@echo "  =========================="
	@echo ""
	@echo "  Phase 1: Admin (at desk with display)"
	@echo "    make admin-init                  Install Xcode CLT, Homebrew, create .config.json"
	@echo "    make admin-install               Install admin tools (bw, jq)"
	@echo "    make admin-configure             Link admin .zshrc, unlock Bitwarden"
	@echo "    make admin-headless-all          Run all headless setup (user, ssh, energy, firewall, screen-sharing)"
	@echo "    make admin-headless-user         Create ops user"
	@echo "    make admin-headless-ssh          Configure SSH + deploy keys"
	@echo "    make admin-headless-energy       Configure power/sleep settings"
	@echo "    make admin-headless-firewall     Configure firewall"
	@echo "    make admin-headless-screen-sharing  Enable Screen Sharing for ops"
	@echo "    make admin-verify                Run all verification checks"
	@echo ""
	@echo "  Phase 2: Ops (via SSH from work/mac)"
	@echo "    make ops-init                    Clone repo, create .config.json"
	@echo "    make ops-install                 Install ops tools (OrbStack, etc.)"
	@echo "    make ops-disable-wifi            Disable Wi-Fi"
	@echo "    make ops-verify                  Run all verification checks"
	@echo ""
