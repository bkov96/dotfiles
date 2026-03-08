#!/bin/sh
set -e

ENV_DIR="$1"

echo "  Capturing installed packages into Brewfile..."
brew bundle dump --file "$ENV_DIR/Brewfile" --force
