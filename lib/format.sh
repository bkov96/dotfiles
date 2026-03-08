#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Formatting shell scripts with shfmt..."
find "$REPO_DIR" -name "*.sh" | sort | while read -r script; do
  shfmt -w "$script"
  echo "  OK $script"
done

echo "Formatting JSON files with jq..."
find "$REPO_DIR" -name "*.json" | sort | while read -r file; do
  formatted="$(jq . "$file")"
  echo "$formatted" >"$file"
  echo "  OK $file"
done

echo "All files formatted."
