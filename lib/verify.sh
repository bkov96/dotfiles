#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Running shellcheck on all shell scripts..."
find "$REPO_DIR" -name "*.sh" | sort | while read -r script; do
  shellcheck "$script"
  echo "  OK $script"
done
echo "All shellcheck checks passed."

echo "Checking shell script formatting with shfmt..."
find "$REPO_DIR" -name "*.sh" | sort | while read -r script; do
  shfmt -d "$script"
  echo "  OK $script"
done
echo "All shell scripts are properly formatted."

echo "Checking JSON file formatting with jq..."
find "$REPO_DIR" -name "*.json" | sort | while read -r file; do
  formatted="$(jq . "$file")"
  original="$(cat "$file")"
  if [ "$formatted" != "$original" ]; then
    echo "  FAIL $file (not formatted, run 'make format')"
    exit 1
  fi
  echo "  OK $file"
done
echo "All JSON files are properly formatted."
