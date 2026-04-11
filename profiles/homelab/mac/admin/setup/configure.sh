#!/bin/sh
set -e

# shellcheck disable=SC2034
PROFILE_DIR="$1"

# Find repo root by walking up from the script's location
_LIB_DIR="$(
  cd "$(dirname "$0")" || exit
  pwd
)"
while [ ! -f "$_LIB_DIR/lib/log.sh" ] && [ "$_LIB_DIR" != "/" ]; do
  _LIB_DIR="$(dirname "$_LIB_DIR")"
done
REPO_DIR="$_LIB_DIR"

# shellcheck source=/dev/null
. "$REPO_DIR/lib/log.sh"

log_header "Configuring admin environment..."

# Link admin .zshrc (derive path from script location, not env vars)
ADMIN_ZSHRC="$(
  cd "$(dirname "$0")/../dotfiles" || exit
  pwd
)/.zshrc"
if [ -L "$HOME/.zshrc" ] && [ "$(readlink "$HOME/.zshrc")" = "$ADMIN_ZSHRC" ]; then
  log_skip ".zshrc already linked"
else
  ln -sf "$ADMIN_ZSHRC" "$HOME/.zshrc"
  log_ok "Linked .zshrc -> ~/.zshrc"
fi

# Unlock Bitwarden (needed for headless scripts to resolve bw:// references)
log_info "Unlocking Bitwarden vault..."
sh "$REPO_DIR/lib/unlock.sh"
log_ok "Bitwarden vault unlocked"

log_done
