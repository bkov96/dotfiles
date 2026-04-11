#!/bin/sh
set -e

PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../../lib/log.sh"
# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../../lib/resolve.sh"

log_header "Configuring Screen Sharing..."

BW_ITEM="dotfiles/$DOTFILES_PROFILE/$DOTFILES_PLATFORM"

if has_bw_refs "$PROFILE_DIR/.config.json"; then
  ensure_bw_session
  fetch_bw_item "$BW_ITEM"
fi

OPS_USER=$(resolve_value "$(jq -r '.env.OPS_USER' "$PROFILE_DIR/.config.json")")

# Enable Screen Sharing via launchd
if launchctl list 2>/dev/null | grep -q "com.apple.screensharing"; then
  log_skip "Screen Sharing already enabled"
else
  log_info "Enabling Screen Sharing..."
  sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist
  log_ok "Screen Sharing enabled"
fi

# Restrict Screen Sharing to ops user only via access group
if dseditgroup -o checkmember -m "$OPS_USER" com.apple.access_screensharing >/dev/null 2>&1; then
  log_skip "User '$OPS_USER' already in Screen Sharing access group"
else
  log_info "Restricting Screen Sharing to '$OPS_USER'..."
  sudo dseditgroup -o create -q com.apple.access_screensharing 2>/dev/null || true
  sudo dseditgroup -o edit -a "$OPS_USER" -t user com.apple.access_screensharing
  log_ok "Screen Sharing restricted to '$OPS_USER'"
fi

# Prompt for manual auto-login step
log_header "Manual step required: Auto-login for '$OPS_USER'"
log_info "Open System Settings > Users & Groups > Automatic Login"
log_info "Select '$OPS_USER' from the dropdown"
log_info "Enter the user's password when prompted"
log_warn "This cannot be reliably scripted on macOS Tahoe"
printf "\n   Press Enter once auto-login is configured..."
read -r _

log_done
