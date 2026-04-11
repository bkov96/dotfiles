#!/bin/sh
set -e

PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../lib/log.sh"

log_header "Verifying ops setup..."

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

check "Internet connectivity" ping -c 1 -t 5 8.8.8.8
check "Profile initialized (.config.json)" test -f "$PROFILE_DIR/.config.json"
check "OrbStack installed" command -v orb

# Wi-Fi check
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
if [ -n "$WIFI_DEVICE" ]; then
  WIFI_POWER=$(networksetup -getairportpower "$WIFI_DEVICE" 2>/dev/null)
  if echo "$WIFI_POWER" | grep -q "Off"; then
    log_ok "Wi-Fi disabled on $WIFI_DEVICE"
    _pass=$((_pass + 1))
  else
    log_fail "Wi-Fi still enabled on $WIFI_DEVICE"
    _fail=$((_fail + 1))
  fi
else
  log_skip "No Wi-Fi interface found"
fi

# Summary
log_header "Verification summary"
log_info "$_pass passed, $_fail failed"

if [ "$_fail" -gt 0 ]; then
  log_warn "Some checks failed — review and fix"
  exit 1
fi

log_ok "All checks passed! Homelab is ready."

log_done
