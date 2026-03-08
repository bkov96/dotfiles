.DEFAULT_GOAL := help

ifndef DOTFILES_ENV
$(error DOTFILES_ENV is not set. Export it in your .zshrc or pass it as an argument)
endif
ifndef DOTFILES_PLATFORM
$(error DOTFILES_PLATFORM is not set. Export it in your .zshrc or pass it as an argument)
endif

ENV_DIR := environments/$(DOTFILES_ENV)/$(DOTFILES_PLATFORM)
DOTFILES_DIR := $(ENV_DIR)/dotfiles

help:
	@sh lib/help.sh $(DOTFILES_ENV) $(DOTFILES_PLATFORM)

init:
	@echo "Initializing $(DOTFILES_ENV)/$(DOTFILES_PLATFORM)..."
	@sh $(ENV_DIR)/setup/init.sh $(ENV_DIR)
	@echo "Done."

install:
	@echo "Installing dependencies for $(DOTFILES_ENV)/$(DOTFILES_PLATFORM)..."
	@sh $(ENV_DIR)/setup/install.sh $(ENV_DIR)
	@echo "Done."

capture:
	@echo "Capturing installed packages for $(DOTFILES_ENV)/$(DOTFILES_PLATFORM)..."
	@sh $(ENV_DIR)/setup/capture.sh $(ENV_DIR)
	@echo "Done."

link: $(ENV_DIR)/.env
	@echo "Linking dotfiles for $(DOTFILES_ENV)/$(DOTFILES_PLATFORM)..."
	@sh lib/link.sh $(ENV_DIR) $(DOTFILES_DIR)
	@echo "Done."

gather: $(ENV_DIR)/.env
	@echo "Gathering dotfiles for $(DOTFILES_ENV)/$(DOTFILES_PLATFORM)..."
	@sh lib/gather.sh $(ENV_DIR) $(DOTFILES_DIR)
	@echo "Done."

env:
	@echo "DOTFILES_ENV=$(DOTFILES_ENV)"
	@echo "DOTFILES_PLATFORM=$(DOTFILES_PLATFORM)"

where:
	@pwd

format:
	@sh lib/format.sh

verify:
	@sh lib/verify.sh

$(ENV_DIR)/.env:
	@echo "Error: $(ENV_DIR)/.env not found. Run 'make init' first."
	@exit 1
