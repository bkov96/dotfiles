.DEFAULT_GOAL := help

ifndef DOTFILES_PROFILE
$(error DOTFILES_PROFILE is not set. Export it in your .zshrc or pass it as an argument)
endif

ifndef DOTFILES_PLATFORM
$(error DOTFILES_PLATFORM is not set. Export it in your .zshrc or pass it as an argument)
endif

ifdef DOTFILES_USER
PROFILE_DIR := profiles/$(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)/$(DOTFILES_USER)
else
PROFILE_DIR := profiles/$(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)
endif
DOTFILES_DIR := $(PROFILE_DIR)/dotfiles

help:
	@sh lib/help.sh $(DOTFILES_PROFILE) $(DOTFILES_PLATFORM) $(DOTFILES_USER)

init:
	@git config core.hooksPath .githooks
	@sh $(PROFILE_DIR)/scripts/init.sh $(PROFILE_DIR)

packages-install:
	@sh $(PROFILE_DIR)/scripts/install.sh $(PROFILE_DIR)

packages-capture:
	@sh $(PROFILE_DIR)/scripts/capture.sh $(PROFILE_DIR)

packages-upgrade:
	@sh $(PROFILE_DIR)/scripts/upgrade.sh $(PROFILE_DIR)

configs-link: $(PROFILE_DIR)/.config.json
	@sh lib/link.sh $(PROFILE_DIR) $(DOTFILES_DIR)
	@if [ -f $(PROFILE_DIR)/scripts/post-link.sh ]; then sh $(PROFILE_DIR)/scripts/post-link.sh $(PROFILE_DIR); fi

configs-gather: $(PROFILE_DIR)/.config.json
	@sh lib/gather.sh $(PROFILE_DIR) $(DOTFILES_DIR)

configs-unlock:
	@sh lib/unlock.sh

scripts-format:
	@sh lib/format.sh

scripts-verify:
	@sh lib/verify.sh

scripts-test:
	@sh profiles/$(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)/test.sh

services-list services-init services-start services-stop services-restart services-status:
	@sh $(PROFILE_DIR)/scripts/services.sh $(subst services-,,$@) "$(SERVICE_NAME)" $(PROFILE_DIR)

env:
	@printf '   \033[36mDOTFILES_PROFILE\033[0m=%s\n' "$(DOTFILES_PROFILE)"
	@printf '   \033[36mDOTFILES_PLATFORM\033[0m=%s\n' "$(DOTFILES_PLATFORM)"
ifdef DOTFILES_USER
	@printf '   \033[36mDOTFILES_USER\033[0m=%s\n' "$(DOTFILES_USER)"
endif

repo-where:
	@pwd

repo-diff:
	@git diff

$(PROFILE_DIR)/.config.json:
	@printf '   \033[1m\033[31m💥  %s/.config.json not found. Run '"'"'make init'"'"' first.\033[0m\n' "$(PROFILE_DIR)" >&2
	@exit 1
