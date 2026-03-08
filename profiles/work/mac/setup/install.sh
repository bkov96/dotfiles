#!/bin/sh
set -e

PROFILE_DIR="$1"

echo "  Running brew bundle..."
brew bundle --file "$PROFILE_DIR/Brewfile"
