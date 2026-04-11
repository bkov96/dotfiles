#!/bin/sh
set -e

PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../../lib/log.sh"
# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../../lib/resolve.sh"

log_header "Creating ops user..."

BW_ITEM="dotfiles/$DOTFILES_PROFILE/$DOTFILES_PLATFORM"

if has_bw_refs "$PROFILE_DIR/.config.json"; then
  ensure_bw_session
  fetch_bw_item "$BW_ITEM"
fi

OPS_USER=$(resolve_value "$(jq -r '.env.OPS_USER' "$PROFILE_DIR/.config.json")")
OPS_PASSWORD=$(resolve_value "$(jq -r '.env.OPS_PASSWORD' "$PROFILE_DIR/.config.json")")

if id "$OPS_USER" >/dev/null 2>&1; then
  log_skip "User '$OPS_USER' already exists"
else
  log_info "Creating user '$OPS_USER' (non-admin)..."
  sudo sysadminctl -addUser "$OPS_USER" -password "$OPS_PASSWORD" -home "/Users/$OPS_USER" -shell /bin/zsh
  log_ok "User '$OPS_USER' created"
fi

# Ensure the user is NOT in the admin group
if dseditgroup -o checkmember -m "$OPS_USER" admin >/dev/null 2>&1; then
  log_warn "User '$OPS_USER' is in the admin group, removing..."
  sudo dseditgroup -o edit -d "$OPS_USER" -t user admin
  log_ok "Removed '$OPS_USER' from admin group"
else
  log_ok "User '$OPS_USER' is not an admin (correct)"
fi

log_done
