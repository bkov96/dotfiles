#!/bin/sh
set -e

PROFILE_DIR="$1"
DOTFILES_DIR="$2"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=/dev/null
. "$(dirname "$0")/log.sh"
# shellcheck source=/dev/null
. "$(dirname "$0")/resolve.sh"

log_header "Linking dotfiles for ${DOTFILES_PROFILE:-}/${DOTFILES_PLATFORM:-}..."

BW_ITEM="dotfiles/$DOTFILES_PROFILE/$DOTFILES_PLATFORM"

if has_bw_refs "$PROFILE_DIR/.config.json"; then
  ensure_bw_session
  fetch_bw_item "$BW_ITEM"
fi

# Export resolved env vars for envsubst
for key in $(jq -r '.env // {} | keys[]' "$PROFILE_DIR/.config.json"); do
  raw=$(jq -r --arg k "$key" '.env[$k]' "$PROFILE_DIR/.config.json")
  value=$(resolve_value "$raw")
  export "$key=$value"
done

# Build envsubst allowlist from config env keys only
ENVSUBST_VARS=$(jq -r '.env // {} | keys[] | "$" + .' "$PROFILE_DIR/.config.json" | tr '\n' ' ')

for src in "$DOTFILES_DIR"/.*; do
  filename=$(basename "$src")
  [ "$filename" = "." ] || [ "$filename" = ".." ] && continue
  default_dest="$HOME/$(echo "$filename" | sed 's/\.tmpl$//')"

  if [ -f "$PROFILE_DIR/.config.json" ]; then
    custom_dest=$(jq -r --arg f "$filename" '.paths[$f] // empty' "$PROFILE_DIR/.config.json")
  fi

  if [ -n "$custom_dest" ]; then
    dest=$(echo "$custom_dest" | sed "s|^~|$HOME|")
  else
    dest="$default_dest"
  fi

  mkdir -p "$(dirname "$dest")"

  if echo "$filename" | grep -q '\.tmpl$'; then
    # Remove a stale symlink so the render replaces it instead of
    # writing through it into the repo (e.g. after a symlink → template switch)
    if [ -L "$dest" ]; then rm "$dest"; fi
    envsubst "$ENVSUBST_VARS" <"$src" >"$dest"
    log_item "Rendered $filename → $dest"
  else
    ln -sf "$REPO_DIR/$src" "$dest"
    log_item "Linked $filename → $dest"
  fi

  unset custom_dest
done

log_done
