.DEFAULT_GOAL := help

ifndef DOTFILES_PROFILE
$(error DOTFILES_PROFILE is not set. Export it in your .zshrc or pass it as an argument)
endif

ifndef DOTFILES_PLATFORM
$(error DOTFILES_PLATFORM is not set. Export it in your .zshrc or pass it as an argument)
endif

PROFILE_DIR := profiles/$(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)
DOTFILES_DIR := $(PROFILE_DIR)/dotfiles

help:
	@sh lib/help.sh $(DOTFILES_PROFILE) $(DOTFILES_PLATFORM)

init:
	@echo "Initializing $(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)..."
	@sh $(PROFILE_DIR)/setup/init.sh $(PROFILE_DIR)
	@echo "Done."

install:
	@echo "Installing dependencies for $(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)..."
	@sh $(PROFILE_DIR)/setup/install.sh $(PROFILE_DIR)
	@echo "Done."

capture:
	@echo "Capturing installed packages for $(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)..."
	@sh $(PROFILE_DIR)/setup/capture.sh $(PROFILE_DIR)
	@echo "Done."

link: $(PROFILE_DIR)/.env
	@echo "Linking dotfiles for $(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)..."
	@sh lib/link.sh $(PROFILE_DIR) $(DOTFILES_DIR)
	@echo "Done."

gather: $(PROFILE_DIR)/.env
	@echo "Gathering dotfiles for $(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)..."
	@sh lib/gather.sh $(PROFILE_DIR) $(DOTFILES_DIR)
	@echo "Done."

env:
	@echo "DOTFILES_PROFILE=$(DOTFILES_PROFILE)"
	@echo "DOTFILES_PLATFORM=$(DOTFILES_PLATFORM)"

where:
	@pwd

format:
	@sh lib/format.sh

verify:
	@sh lib/verify.sh

test:
	@sh profiles/$(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)/test.sh

$(PROFILE_DIR)/.env:
	@echo "Error: $(PROFILE_DIR)/.env not found. Run 'make init' first."
	@exit 1
