#!/bin/sh
set -e

ENV_DIR="$1"

echo "  Running brew bundle..."
brew bundle --file "$ENV_DIR/Brewfile"
