#!/bin/sh
set -e

PROFILE_DIR="$1"

# Find lib/ by walking up from the script's location
_LIB_DIR="$(
  cd "$(dirname "$0")" || exit
  pwd
)"
while [ ! -f "$_LIB_DIR/lib/log.sh" ] && [ "$_LIB_DIR" != "/" ]; do
  _LIB_DIR="$(dirname "$_LIB_DIR")"
done
# shellcheck source=/dev/null
. "$_LIB_DIR/lib/log.sh"

log_header "Capturing installed packages for ${DOTFILES_PROFILE:-}/${DOTFILES_PLATFORM:-}..."
log_info "Running brew bundle dump..."
brew bundle dump --file "$PROFILE_DIR/Brewfile" --force
log_done
