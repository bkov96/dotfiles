#!/bin/sh
set -e

ENV_DIR="$1"

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

# Copy .env.example -> .env if not present
if [ ! -f "$ENV_DIR/.env" ]; then
  cp "$ENV_DIR/.env.example" "$ENV_DIR/.env"
  echo "  Created $ENV_DIR/.env from .env.example"
  echo "  ⚠️  Fill in your values in $ENV_DIR/.env before running 'make link'"
else
  echo "  $ENV_DIR/.env already exists, skipping"
fi

# Copy .config.example.json -> .config.json if not present
if [ -f "$ENV_DIR/.config.example.json" ] && [ ! -f "$ENV_DIR/.config.json" ]; then
  cp "$ENV_DIR/.config.example.json" "$ENV_DIR/.config.json"
  echo "  Created $ENV_DIR/.config.json from .config.example.json"
else
  echo "  $ENV_DIR/.config.json already exists or no example found, skipping"
fi
