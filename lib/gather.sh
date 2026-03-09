#!/bin/sh
set -e

PROFILE_DIR="$1"
DOTFILES_DIR="$2"

# Export env vars from config
eval "$(jq -r '.env // {} | to_entries[] | "export \(.key)=\(.value | @sh)"' "$PROFILE_DIR/.config.json")"

# Get variable names for placeholder replacement
var_names=$(jq -r '.env // {} | keys[]' "$PROFILE_DIR/.config.json")

for src in "$DOTFILES_DIR"/.*; do
  filename=$(basename "$src")
  [ "$filename" = "." ] || [ "$filename" = ".." ] && continue

  # Only process template files; non-template files are symlinked and already tracked
  echo "$filename" | grep -q '\.tmpl$' || continue

  default_dest="$HOME/$(echo "$filename" | sed 's/\.tmpl$//')"

  if [ -f "$PROFILE_DIR/.config.json" ]; then
    custom_dest=$(jq -r --arg f "$filename" '.paths[$f] // empty' "$PROFILE_DIR/.config.json")
  fi

  if [ -n "$custom_dest" ]; then
    dest=$(echo "$custom_dest" | sed "s|^~|$HOME|")
  else
    dest="$default_dest"
  fi

  if [ ! -f "$dest" ]; then
    echo "  SKIP $filename (destination not found: $dest)"
    unset custom_dest
    continue
  fi

  cp "$dest" "$src"

  # Replace each .env value with its ${VAR} placeholder
  for var in $var_names; do
    eval "value=\$$var"
    [ -z "$value" ] && continue
    # Escape BRE metacharacters and forward slashes for sed
    escaped=$(printf '%s' "$value" | sed 's/[\\.*[\^$]/\\&/g; s/\//\\\//g')
    tmp=$(mktemp)
    # shellcheck disable=SC2001
    sed "s/$escaped/\${${var}}/g" "$src" >"$tmp"
    mv "$tmp" "$src"
  done

  echo "  Gathered $dest -> $filename"
  unset custom_dest
done
