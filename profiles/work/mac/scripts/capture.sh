#!/bin/sh
set -e

PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../lib/log.sh"

log_header "Capturing installed packages for ${DOTFILES_PROFILE:-}/${DOTFILES_PLATFORM:-}..."
log_info "Running brew bundle dump..."
brew bundle dump --file "$PROFILE_DIR/Brewfile" --force
log_done
