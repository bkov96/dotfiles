#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=/dev/null
. "$(dirname "$0")/log.sh"

log_header "Formatting shell scripts with shfmt..."
find "$REPO_DIR" -name "*.sh" | sort | while read -r script; do
  log_task "$script" shfmt -w "$script"
done

log_header "Formatting JSON files with jq..."
find "$REPO_DIR" -name "*.json" | sort | while read -r file; do
  formatted="$(jq . "$file")"
  echo "$formatted" >"$file"
  log_ok "$file"
done

log_done
