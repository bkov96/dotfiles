#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=/dev/null
. "$(dirname "$0")/log.sh"

log_header "Running shellcheck on all shell scripts..."
for script in $(find "$REPO_DIR" -name "*.sh" | sort); do
  log_task "$script" shellcheck "$script"
done
log_info "All shellcheck checks passed."

log_header "Checking shell script formatting with shfmt..."
for script in $(find "$REPO_DIR" -name "*.sh" | sort); do
  log_task "$script" shfmt -d "$script"
done
log_info "All shell scripts are properly formatted."

log_header "Checking JSON file formatting with jq..."
json_result=0
for file in $(find "$REPO_DIR" -name "*.json" | sort); do
  if ! jq . "$file" | diff -q - "$file" >/dev/null 2>&1; then
    log_fail "$file (not formatted, run 'make format')"
    json_result=1
  else
    log_ok "$file"
  fi
done
if [ "$json_result" -ne 0 ]; then
  exit 1
fi
log_info "All JSON files are properly formatted."

log_header "Scanning for secrets with gitleaks..."
log_task "gitleaks" gitleaks dir "$REPO_DIR" --no-banner -v
log_info "No secrets detected."

log_done
