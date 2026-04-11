#!/bin/sh
set -e

PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../lib/log.sh"
# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../lib/resolve.sh"

log_header "Verifying admin bootstrap..."

BW_ITEM="dotfiles/$DOTFILES_PROFILE/$DOTFILES_PLATFORM"

if has_bw_refs "$PROFILE_DIR/.config.json"; then
  ensure_bw_session
  fetch_bw_item "$BW_ITEM"
fi

OPS_USER=$(resolve_value "$(jq -r '.env.OPS_USER' "$PROFILE_DIR/.config.json")")
FW="/usr/libexec/ApplicationFirewall/socketfilterfw"

_pass=0
_fail=0

check() {
  label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    log_ok "$label"
    _pass=$((_pass + 1))
  else
    log_fail "$label"
    _fail=$((_fail + 1))
  fi
}

check_grep() {
  label="$1"
  cmd="$2"
  pattern="$3"
  if eval "$cmd" 2>/dev/null | grep -q "$pattern"; then
    log_ok "$label"
    _pass=$((_pass + 1))
  else
    log_fail "$label"
    _fail=$((_fail + 1))
  fi
}

# User checks
check "ops user '$OPS_USER' exists" id "$OPS_USER"

# SSH checks
check "Remote Login is on (port 22 listening)" nc -z localhost 22
check_grep "sshd_config: PasswordAuthentication no" "cat /etc/ssh/sshd_config" "^PasswordAuthentication no"
check "Authorized key exists for '$OPS_USER'" sudo test -f "/Users/$OPS_USER/.ssh/authorized_keys"

# Energy checks
check_grep "sleep is 0" "pmset -g" " sleep.*0"
check_grep "disksleep is 0" "pmset -g" " disksleep.*0"
check_grep "displaysleep is 0" "pmset -g" " displaysleep.*0"
check_grep "Wake on LAN is 1" "pmset -g" " womp.*1"
check_grep "Auto-restart is 1" "pmset -g" " autorestart.*1"

# Firewall checks
check_grep "Firewall is enabled" "sudo $FW --getglobalstate" "enabled"

# Screen Sharing checks
check_grep "Screen Sharing is running" "launchctl list" "com.apple.screensharing"

# Manual check
log_header "Manual verification required"
log_info "Is auto-login configured for '$OPS_USER'? (y/n)"
printf "   > "
read -r auto_login_ok
if [ "$auto_login_ok" = "y" ] || [ "$auto_login_ok" = "Y" ]; then
  log_ok "Auto-login confirmed by user"
  _pass=$((_pass + 1))
else
  log_fail "Auto-login not confirmed"
  _fail=$((_fail + 1))
fi

# Summary
log_header "Verification summary"
log_info "$_pass passed, $_fail failed"

if [ "$_fail" -gt 0 ]; then
  log_warn "Some checks failed — fix them before relocating"
  exit 1
fi

log_ok "All checks passed!"

# Relocation prompt
printf "\n"
log_info "Ready to power off and relocate? (y/n)"
printf "   > "
read -r relocate_ok
if [ "$relocate_ok" = "y" ] || [ "$relocate_ok" = "Y" ]; then
  log_info "Shutting down..."
  sudo shutdown -h now
else
  log_info "Skipping shutdown. Run 'sudo shutdown -h now' when ready."
fi

log_done
