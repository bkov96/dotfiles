#!/bin/sh
set -e

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../../../lib/log.sh"

log_header "Configuring energy settings..."

set_pmset() {
  key="$1"
  value="$2"

  current=$(pmset -g | grep -w "$key" | awk '{print $2}')
  if [ "$current" = "$value" ]; then
    log_skip "$key already set to $value"
  else
    sudo pmset -a "$key" "$value"
    log_ok "$key set to $value"
  fi
}

# Disable all sleep
set_pmset sleep 0
set_pmset disksleep 0
set_pmset displaysleep 0

# Wake on LAN
set_pmset womp 1

# Auto-restart after power failure
set_pmset autorestart 1

log_done
