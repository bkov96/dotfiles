ENV ?= work
PLATFORM ?= mac
ENV_DIR := environments/$(ENV)/$(PLATFORM)
DOTFILES_DIR := $(ENV_DIR)/dotfiles

link: $(ENV_DIR)/.env
	@echo "Linking dotfiles for $(ENV)/$(PLATFORM)..."
	set -a && . $(ENV_DIR)/.env && set +a && \
		envsubst < $(DOTFILES_DIR)/.gitconfig.tmpl > $(HOME)/.gitconfig
	ln -sf $(CURDIR)/$(DOTFILES_DIR)/.zshrc $(HOME)/.zshrc
	@echo "Done."

$(ENV_DIR)/.env:
	@echo "Error: $(ENV_DIR)/.env not found. Copy $(ENV_DIR)/.env.example and fill in values."
	@exit 1
