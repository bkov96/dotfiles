#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Running shellcheck on all shell scripts..."
for script in $(find "$REPO_DIR" -name "*.sh" | sort); do
  shellcheck "$script"
  echo "  OK $script"
done
echo "All shellcheck checks passed."

echo "Checking shell script formatting with shfmt..."
for script in $(find "$REPO_DIR" -name "*.sh" | sort); do
  shfmt -d "$script"
  echo "  OK $script"
done
echo "All shell scripts are properly formatted."

echo "Checking JSON file formatting with jq..."
json_result=0
for file in $(find "$REPO_DIR" -name "*.json" | sort); do
  formatted="$(jq . "$file")"
  original="$(cat "$file")"
  if [ "$formatted" != "$original" ]; then
    echo "  FAIL $file (not formatted, run 'make format')"
    json_result=1
  else
    echo "  OK $file"
  fi
done
if [ "$json_result" -ne 0 ]; then
  exit 1
fi
echo "All JSON files are properly formatted."
