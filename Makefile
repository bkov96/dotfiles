.DEFAULT_GOAL := help

ENV ?= work
PLATFORM ?= mac
ENV_DIR := environments/$(ENV)/$(PLATFORM)
DOTFILES_DIR := $(ENV_DIR)/dotfiles

help:
	@sh lib/help.sh $(ENV) $(PLATFORM)

init:
	@echo "Initializing $(ENV)/$(PLATFORM)..."
	@sh $(ENV_DIR)/setup/init.sh $(ENV_DIR)
	@echo "Done."

install:
	@echo "Installing dependencies for $(ENV)/$(PLATFORM)..."
	@sh $(ENV_DIR)/setup/install.sh $(ENV_DIR)
	@echo "Done."

capture:
	@echo "Capturing installed packages for $(ENV)/$(PLATFORM)..."
	@sh $(ENV_DIR)/setup/capture.sh $(ENV_DIR)
	@echo "Done."

link: $(ENV_DIR)/.env
	@echo "Linking dotfiles for $(ENV)/$(PLATFORM)..."
	@sh lib/link.sh $(ENV_DIR) $(DOTFILES_DIR)
	@echo "Done."

format:
	@sh lib/format.sh

verify:
	@sh lib/verify.sh

$(ENV_DIR)/.env:
	@echo "Error: $(ENV_DIR)/.env not found. Run 'make init' first."
	@exit 1
