#!/bin/sh
set -e

PROFILE_DIR="$1"

# Install Xcode Command Line Tools if not present
if ! xcode-select -p >/dev/null 2>&1; then
  echo "  Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "  ⚠️  Complete the Xcode CLT installation dialog, then re-run 'make init'"
  exit 0
else
  echo "  Xcode Command Line Tools already installed"
fi

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
  echo "  Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "  ⚠️  Follow Homebrew's post-install instructions to add it to your PATH, then re-run 'make init'"
  exit 0
else
  echo "  Homebrew already installed"
fi

# Copy .config.example.json -> .config.json with bw:// references if not present
if [ -f "$PROFILE_DIR/.config.example.json" ] && [ ! -f "$PROFILE_DIR/.config.json" ]; then
  jq '.env |= with_entries(.value = "bw://\(.key)")' "$PROFILE_DIR/.config.example.json" >"$PROFILE_DIR/.config.json"
  echo "  Created $PROFILE_DIR/.config.json with bw:// references"
  echo "  ⚠️  Run 'make unlock' before 'make link' to resolve secrets from Bitwarden"
else
  echo "  $PROFILE_DIR/.config.json already exists or no example found, skipping"
fi
