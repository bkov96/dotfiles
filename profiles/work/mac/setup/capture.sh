#!/bin/sh
set -e

PROFILE_DIR="$1"

echo "  Capturing installed packages into Brewfile..."
brew bundle dump --file "$PROFILE_DIR/Brewfile" --force
