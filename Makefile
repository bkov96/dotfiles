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
	@sh $(PROFILE_DIR)/setup/init.sh $(PROFILE_DIR)

install:
	@sh $(PROFILE_DIR)/setup/install.sh $(PROFILE_DIR)

capture:
	@sh $(PROFILE_DIR)/setup/capture.sh $(PROFILE_DIR)

link: $(PROFILE_DIR)/.config.json
	@sh lib/link.sh $(PROFILE_DIR) $(DOTFILES_DIR)

gather: $(PROFILE_DIR)/.config.json
	@sh lib/gather.sh $(PROFILE_DIR) $(DOTFILES_DIR)

unlock:
	@sh lib/unlock.sh

env:
	@printf '   \033[36mDOTFILES_PROFILE\033[0m=%s\n' "$(DOTFILES_PROFILE)"
	@printf '   \033[36mDOTFILES_PLATFORM\033[0m=%s\n' "$(DOTFILES_PLATFORM)"

where:
	@pwd

format:
	@sh lib/format.sh

verify:
	@sh lib/verify.sh

test:
	@sh profiles/$(DOTFILES_PROFILE)/$(DOTFILES_PLATFORM)/test.sh

$(PROFILE_DIR)/.config.json:
	@printf '   \033[1m\033[31m💥  %s/.config.json not found. Run '"'"'make init'"'"' first.\033[0m\n' "$(PROFILE_DIR)" >&2
	@exit 1
