# shellcheck shell=sh
# Shared Bitwarden resolution helpers.
# Source this file; do not execute directly.

# Resolve the lib/ directory path. When sourced from scripts outside lib/,
# dirname "$0" points to the caller's directory, not lib/. Walk up the
# directory tree from $0 to find the repo root containing lib/resolve.sh.
_RESOLVE_LIB_DIR="$(
  cd "$(dirname "$0")" || exit
  pwd
)"
if [ ! -f "$_RESOLVE_LIB_DIR/resolve.sh" ]; then
  _resolve_candidate="$_RESOLVE_LIB_DIR"
  while [ "$_resolve_candidate" != "/" ]; do
    if [ -f "$_resolve_candidate/lib/resolve.sh" ]; then
      _RESOLVE_LIB_DIR="$_resolve_candidate/lib"
      break
    fi
    _resolve_candidate="$(dirname "$_resolve_candidate")"
  done
  unset _resolve_candidate
fi

# Source log.sh if not already loaded
if ! command -v log_ok >/dev/null 2>&1; then
  # shellcheck source=/dev/null
  . "$_RESOLVE_LIB_DIR/log.sh"
fi

# Check if any env values use bw:// references
has_bw_refs() {
  jq -e '.env // {} | to_entries[] | select(.value | startswith("bw://"))' "$1" >/dev/null 2>&1
}

# Load BW_SESSION from .bw_session file if not already set in environment
load_bw_session() {
  if [ -z "$BW_SESSION" ]; then
    session_file="$(cd "$_RESOLVE_LIB_DIR/.." && pwd)/.bw_session"
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
    log_error "bw:// references found but Bitwarden CLI (bw) is not installed. Run 'make install' first."
    exit 1
  fi

  load_bw_session

  STATUS=$(bw status 2>/dev/null | jq -r '.status')
  case "$STATUS" in
  unlocked)
    return
    ;;
  locked | unauthenticated)
    log_info "Bitwarden session expired or missing, re-authenticating..." >&2
    _LOG_NESTED=1 sh "$_RESOLVE_LIB_DIR/unlock.sh"
    BW_SESSION=""
    load_bw_session
    if [ -z "$BW_SESSION" ]; then
      log_error "Failed to re-authenticate with Bitwarden."
      exit 1
    fi
    ;;
  *)
    log_error "Unexpected Bitwarden vault status '$STATUS'"
    exit 1
    ;;
  esac
}

# Fetch the Bitwarden item JSON into BW_ITEM_JSON (call once before resolve_value)
fetch_bw_item() {
  bw_item="$1"
  BW_ITEM_JSON=$(bw get item "$bw_item" 2>/dev/null) || {
    log_error "Could not fetch Bitwarden item '$bw_item'."
    exit 1
  }
  if ! printf '%s' "$BW_ITEM_JSON" | jq -e '.fields' >/dev/null 2>&1; then
    log_error "Bitwarden item '$bw_item' has no custom fields. Add fields for each env var."
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
      log_error "Field '$field' not found in Bitwarden item"
      exit 1
    fi
    printf '%s' "$resolved"
    ;;
  *)
    printf '%s' "$val"
    ;;
  esac
}
