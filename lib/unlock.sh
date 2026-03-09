#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=/dev/null
. "$(dirname "$0")/log.sh"

# Use macOS system CA bundle for Node.js (fixes certificate errors with bw CLI)
if [ -f /etc/ssl/cert.pem ]; then
  export NODE_EXTRA_CA_CERTS=/etc/ssl/cert.pem
fi

if ! command -v bw >/dev/null 2>&1; then
  log_error "Bitwarden CLI (bw) is not installed. Run 'make install' first."
  exit 1
fi

STATUS=$(bw status 2>/dev/null | jq -r '.status')

case "$STATUS" in
unauthenticated)
  if [ -n "$BW_CLIENTID" ] && [ -n "$BW_CLIENTSECRET" ]; then
    log_info "Logging in with API key..."
    bw login --apikey
  else
    log_info "Logging in to Bitwarden..."
    bw login
  fi
  ;;
locked | unlocked) ;;
*)
  log_error "Unexpected vault status '$STATUS'"
  exit 1
  ;;
esac

log_info "Unlocking Bitwarden vault..."
SESSION=$(bw unlock --raw)

if [ -z "$SESSION" ]; then
  log_error "Failed to obtain Bitwarden session."
  exit 1
fi

export BW_SESSION="$SESSION"
log_task "Syncing vault" bw sync

echo "$SESSION" >"$REPO_DIR/.bw_session"
chmod 600 "$REPO_DIR/.bw_session"
log_info "Session saved to .bw_session."
if [ -z "$_LOG_NESTED" ]; then log_done; fi
