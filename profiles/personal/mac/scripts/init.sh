#!/bin/sh
set -e

PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../lib/log.sh"

log_header "Initializing ${DOTFILES_PROFILE:-}/${DOTFILES_PLATFORM:-}..."

# Install Xcode Command Line Tools if not present
if ! xcode-select -p >/dev/null 2>&1; then
  log_info "Installing Xcode Command Line Tools..."
  xcode-select --install
  log_warn "Complete the Xcode CLT installation dialog, then re-run 'make init'"
  exit 0
else
  log_ok "Xcode Command Line Tools already installed"
fi

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  log_warn "Follow Homebrew's post-install instructions to add it to your PATH, then re-run 'make init'"
  exit 0
else
  log_ok "Homebrew already installed"
fi

# Copy .config.example.json -> .config.json with bw:// references if not present
if [ -f "$PROFILE_DIR/.config.example.json" ] && [ ! -f "$PROFILE_DIR/.config.json" ]; then
  jq '.env |= with_entries(.value = "bw://\(.key)")' "$PROFILE_DIR/.config.example.json" >"$PROFILE_DIR/.config.json"
  log_ok "Created $PROFILE_DIR/.config.json with bw:// references"
  log_warn "Run 'dotfiles configs unlock' before 'dotfiles configs link' to resolve secrets from Bitwarden"
else
  log_ok "$PROFILE_DIR/.config.json already exists or no example found, skipping"
fi

log_done
