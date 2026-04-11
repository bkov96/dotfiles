#!/bin/sh
set -e

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../../lib/log.sh"

FW="/usr/libexec/ApplicationFirewall/socketfilterfw"

log_header "Configuring firewall..."

# Enable firewall
if sudo "$FW" --getglobalstate | grep -q "enabled"; then
  log_skip "Firewall already enabled"
else
  sudo "$FW" --setglobalstate on
  log_ok "Firewall enabled"
fi

# Disable stealth mode (allow ping)
if sudo "$FW" --getstealthmode | grep -q "disabled"; then
  log_skip "Stealth mode already disabled"
else
  sudo "$FW" --setstealthmode off
  log_ok "Stealth mode disabled"
fi

# Allow SSH (Remote Login)
SSH_PATH="/usr/libexec/sshd-keygen-wrapper"
if sudo "$FW" --listapps 2>/dev/null | grep -q "$SSH_PATH"; then
  log_skip "SSH already allowed through firewall"
else
  sudo "$FW" --add "$SSH_PATH"
  sudo "$FW" --unblockapp "$SSH_PATH"
  log_ok "SSH allowed through firewall"
fi

# Allow Screen Sharing (VNC)
SCREEN_SHARING_PATH="/System/Library/CoreServices/Screen Sharing.app"
if sudo "$FW" --listapps 2>/dev/null | grep -q "Screen Sharing"; then
  log_skip "Screen Sharing already allowed through firewall"
else
  sudo "$FW" --add "$SCREEN_SHARING_PATH"
  sudo "$FW" --unblockapp "$SCREEN_SHARING_PATH"
  log_ok "Screen Sharing allowed through firewall"
fi

log_done
