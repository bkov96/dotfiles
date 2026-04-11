#!/bin/sh
set -e

# shellcheck disable=SC2034
PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../lib/log.sh"

log_header "Installing admin dependencies for ${DOTFILES_PROFILE:-}/${DOTFILES_PLATFORM:-}..."

# Admin tools (bitwarden-cli and jq for bootstrap scripts)
log_info "Running brew bundle for admin..."
brew bundle --file "$PROFILE_DIR/Brewfile"
log_ok "Admin packages installed"

# Cask packages from ops Brewfile (ops can't install casks — Homebrew is admin-owned)
OPS_BREWFILE="$(dirname "$PROFILE_DIR")/ops/Brewfile"
if [ -f "$OPS_BREWFILE" ]; then
  log_info "Running brew bundle for ops casks..."
  brew bundle --file "$OPS_BREWFILE"
  log_ok "Ops packages installed"
fi

log_done
