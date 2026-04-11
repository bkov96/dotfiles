#!/bin/sh
set -e

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../lib/log.sh"

log_header "Disabling Wi-Fi..."

# Verify Ethernet connectivity first
log_info "Checking internet connectivity via Ethernet..."
if ! ping -c 1 -t 5 8.8.8.8 >/dev/null 2>&1; then
  log_error "No internet connectivity — aborting Wi-Fi disable to avoid losing access"
  exit 1
fi
log_ok "Internet connectivity confirmed"

# Get Wi-Fi interface name (typically en0 on Mac Mini)
WIFI_DEVICE=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')

if [ -z "$WIFI_DEVICE" ]; then
  log_skip "No Wi-Fi interface found"
  exit 0
fi

WIFI_POWER=$(networksetup -getairportpower "$WIFI_DEVICE" 2>/dev/null)
if echo "$WIFI_POWER" | grep -q "Off"; then
  log_skip "Wi-Fi already disabled on $WIFI_DEVICE"
else
  log_info "Disabling Wi-Fi on $WIFI_DEVICE..."
  networksetup -setairportpower "$WIFI_DEVICE" off
  log_ok "Wi-Fi disabled on $WIFI_DEVICE"
fi

log_done
