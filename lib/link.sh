#!/bin/sh
set -e

PROFILE_DIR="$1"
DOTFILES_DIR="$2"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

set -a
# shellcheck source=/dev/null
. "$PROFILE_DIR/.env"
set +a

# Build envsubst allowlist from .env variable names only
ENVSUBST_VARS=$(grep -v '^#' "$PROFILE_DIR/.env" | grep '=' | sed 's/=.*//' | sed 's/^/\$/' | tr '\n' ' ')

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
