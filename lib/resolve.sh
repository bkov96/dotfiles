# shellcheck shell=sh
# Shared Bitwarden resolution helpers.
# Source this file; do not execute directly.

# Check if any env values use bw:// references
has_bw_refs() {
  jq -e '.env // {} | to_entries[] | select(.value | startswith("bw://"))' "$1" >/dev/null 2>&1
}

# Load BW_SESSION from .bw_session file if not already set in environment
load_bw_session() {
  if [ -z "$BW_SESSION" ]; then
    session_file="$(cd "$(dirname "$0")/.." && pwd)/.bw_session"
    if [ -f "$session_file" ]; then
      BW_SESSION=$(cat "$session_file")
      export BW_SESSION
    fi
  fi
}

# Ensure Bitwarden session is valid; auto-unlock if expired or missing
ensure_bw_session() {
  if [ -f /etc/ssl/cert.pem ]; then
    export NODE_EXTRA_CA_CERTS=/etc/ssl/cert.pem
  fi

  if ! command -v bw >/dev/null 2>&1; then
    echo "Error: bw:// references found but Bitwarden CLI (bw) is not installed. Run 'make install' first." >&2
    exit 1
  fi

  load_bw_session

  STATUS=$(bw status 2>/dev/null | jq -r '.status')
  case "$STATUS" in
  unlocked)
    return
    ;;
  locked | unauthenticated)
    echo "  Bitwarden session expired or missing, re-authenticating..." >&2
    sh "$(dirname "$0")/unlock.sh"
    BW_SESSION=""
    load_bw_session
    if [ -z "$BW_SESSION" ]; then
      echo "Error: failed to re-authenticate with Bitwarden." >&2
      exit 1
    fi
    ;;
  *)
    echo "Error: unexpected Bitwarden vault status '$STATUS'" >&2
    exit 1
    ;;
  esac
}

# Fetch the Bitwarden item JSON into BW_ITEM_JSON (call once before resolve_value)
fetch_bw_item() {
  bw_item="$1"
  BW_ITEM_JSON=$(bw get item "$bw_item" 2>/dev/null) || {
    echo "Error: could not fetch Bitwarden item '$bw_item'." >&2
    exit 1
  }
  if ! printf '%s' "$BW_ITEM_JSON" | jq -e '.fields' >/dev/null 2>&1; then
    echo "Error: Bitwarden item '$bw_item' has no custom fields. Add fields for each env var." >&2
    exit 1
  fi
}

# Resolve a single env value: bw:// -> field from BW_ITEM_JSON, plain -> passthrough
resolve_value() {
  val="$1"
  case "$val" in
  bw://*)
    field="${val#bw://}"
    resolved=$(printf '%s' "$BW_ITEM_JSON" | jq -r --arg f "$field" '.fields[] | select(.name == $f) | .value')
    if [ -z "$resolved" ]; then
      echo "Error: field '$field' not found in Bitwarden item" >&2
      exit 1
    fi
    printf '%s' "$resolved"
    ;;
  *)
    printf '%s' "$val"
    ;;
  esac
}
