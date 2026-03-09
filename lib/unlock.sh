#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Use macOS system CA bundle for Node.js (fixes certificate errors with bw CLI)
if [ -f /etc/ssl/cert.pem ]; then
  export NODE_EXTRA_CA_CERTS=/etc/ssl/cert.pem
fi

if ! command -v bw >/dev/null 2>&1; then
  echo "Error: Bitwarden CLI (bw) is not installed. Run 'make install' first." >&2
  exit 1
fi

STATUS=$(bw status 2>/dev/null | jq -r '.status')

case "$STATUS" in
unauthenticated)
  if [ -n "$BW_CLIENTID" ] && [ -n "$BW_CLIENTSECRET" ]; then
    echo "Logging in with API key..."
    bw login --apikey
  else
    echo "Logging in to Bitwarden..."
    bw login
  fi
  ;;
locked | unlocked) ;;
*)
  echo "Error: unexpected vault status '$STATUS'" >&2
  exit 1
  ;;
esac

echo "Unlocking Bitwarden vault..."
SESSION=$(bw unlock --raw)

if [ -z "$SESSION" ]; then
  echo "Error: failed to obtain Bitwarden session." >&2
  exit 1
fi

export BW_SESSION="$SESSION"
bw sync >/dev/null 2>&1 || true

echo "$SESSION" >"$REPO_DIR/.bw_session"
chmod 600 "$REPO_DIR/.bw_session"
echo "Bitwarden vault unlocked. Session saved to .bw_session."
