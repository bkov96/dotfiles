#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Running shellcheck on all shell scripts..."
find "$REPO_DIR" -name "*.sh" | sort | while read -r script; do
  shellcheck "$script"
  echo "  OK $script"
done
echo "All scripts passed."
