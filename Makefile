ENV ?= work
PLATFORM ?= mac
ENV_DIR := environments/$(ENV)/$(PLATFORM)
DOTFILES_DIR := $(ENV_DIR)/dotfiles

link: $(ENV_DIR)/.env
	@echo "Linking dotfiles for $(ENV)/$(PLATFORM)..."
	@sh lib/link.sh $(ENV_DIR) $(DOTFILES_DIR)
	@echo "Done."

$(ENV_DIR)/.env:
	@echo "Error: $(ENV_DIR)/.env not found. Copy $(ENV_DIR)/.env.example and fill in values."
	@exit 1
