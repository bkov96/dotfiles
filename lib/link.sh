#!/bin/sh
set -e

PROFILE_DIR="$1"
DOTFILES_DIR="$2"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Export env vars from config for envsubst
eval "$(jq -r '.env // {} | to_entries[] | "export \(.key)=\(.value | @sh)"' "$PROFILE_DIR/.config.json")"

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

  if echo "$filename" | grep -q '\.tmpl$'; then
    envsubst "$ENVSUBST_VARS" <"$src" >"$dest"
    echo "  Rendered $filename -> $dest"
  else
    ln -sf "$REPO_DIR/$src" "$dest"
    echo "  Linked $filename -> $dest"
  fi

  unset custom_dest
done
