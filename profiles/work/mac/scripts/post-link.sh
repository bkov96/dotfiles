#!/bin/sh
set -e

# shellcheck disable=SC2034
PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../lib/log.sh"

log_header "Running post-link for ${DOTFILES_PROFILE:-}/${DOTFILES_PLATFORM:-}..."

# Decode rendered files whose env var name ends in _B64.
# Scans .config.json paths: for each path entry whose template was rendered
# using a _B64 env var, the rendered file contains raw base64 and needs decoding.
decode_b64_file() {
  dest="$1"
  label="$2"
  dest=$(echo "$dest" | sed "s|^~|$HOME|")

  if [ ! -f "$dest" ]; then
    return
  fi

  content=$(cat "$dest")

  # Skip if already decoded (PEM private key or OpenSSH public key format)
  case "$content" in
  "-----BEGIN"*)
    log_skip "$dest already decoded ($label)"
    return
    ;;
  "ssh-"*)
    log_skip "$dest already decoded ($label)"
    return
    ;;
  esac

  decoded=$(printf '%s' "$content" | base64 -d 2>/dev/null || true)
  if [ -n "$decoded" ]; then
    printf '%s\n' "$decoded" >"$dest"
    log_ok "Decoded $dest ($label)"
  fi
}

# Decode SSH keys (rendered as base64 by link.sh from _B64 env vars)
# shellcheck disable=SC2088
decode_b64_file "~/.ssh/id_ed25519_homelab" "SSH_PRIVATE_KEY_B64"
# shellcheck disable=SC2088
decode_b64_file "~/.ssh/id_ed25519_homelab.pub" "SSH_PUBLIC_KEY_B64"

# Set SSH key permissions
if [ -f "$HOME/.ssh/id_ed25519_homelab" ]; then
  chmod 600 "$HOME/.ssh/id_ed25519_homelab"
  log_ok "Set permissions on ~/.ssh/id_ed25519_homelab"
fi

if [ -f "$HOME/.ssh/id_ed25519_homelab.pub" ]; then
  chmod 644 "$HOME/.ssh/id_ed25519_homelab.pub"
  log_ok "Set permissions on ~/.ssh/id_ed25519_homelab.pub"
fi

log_done
