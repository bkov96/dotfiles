#!/bin/sh
set -e

PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../lib/log.sh"

log_header "Installing ops dependencies for ${DOTFILES_PROFILE:-}/${DOTFILES_PLATFORM:-}..."
log_info "Running brew bundle..."
brew bundle --file "$PROFILE_DIR/Brewfile"
log_done
