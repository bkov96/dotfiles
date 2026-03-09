# shellcheck shell=sh
# Shared logging utilities.
# Source this file; do not execute directly.

# Enable colors only when writing to a terminal
if [ -t 1 ]; then
  _LOG_BOLD=$(printf '\033[1m')
  _LOG_DIM=$(printf '\033[2m')
  _LOG_RED=$(printf '\033[31m')
  _LOG_GREEN=$(printf '\033[32m')
  _LOG_YELLOW=$(printf '\033[33m')
  _LOG_CYAN=$(printf '\033[36m')
  _LOG_RESET=$(printf '\033[0m')
else
  _LOG_BOLD=''
  _LOG_DIM=''
  _LOG_RED=''
  _LOG_GREEN=''
  _LOG_YELLOW=''
  _LOG_CYAN=''
  _LOG_RESET=''
fi

# Phase header: bold "🔷  message" (blank line before for visual separation)
log_header() {
  printf '\n%s🔷  %s%s\n\n' "$_LOG_BOLD" "$*" "$_LOG_RESET"
}

# Per-item success: green "✅  message"
log_ok() {
  printf '   %s✅  %s%s\n' "$_LOG_GREEN" "$*" "$_LOG_RESET"
}

# Per-item failure: red "❌  message"
log_fail() {
  printf '   %s❌  %s%s\n' "$_LOG_RED" "$*" "$_LOG_RESET"
}

# Skipped item: dim "⏭️   message"
log_skip() {
  printf '   %s⏭️   %s%s\n' "$_LOG_DIM" "$*" "$_LOG_RESET"
}

# Informational: cyan "ℹ️   message"
log_info() {
  printf '   %sℹ️   %s%s\n' "$_LOG_CYAN" "$*" "$_LOG_RESET"
}

# Warning: yellow "⚠️   message"
log_warn() {
  printf '   %s⚠️   %s%s\n' "$_LOG_YELLOW" "$*" "$_LOG_RESET"
}

# Fatal error: bold red "💥  message" (always to stderr)
log_error() {
  printf '   %s%s💥  %s%s\n' "$_LOG_BOLD" "$_LOG_RED" "$*" "$_LOG_RESET" >&2
}

# Phase complete: bold green "✨  Done!" (blank line after for visual separation)
log_done() {
  printf '\n%s%s✨  Done!%s\n\n' "$_LOG_BOLD" "$_LOG_GREEN" "$_LOG_RESET"
}

# Generic action item: cyan arrow "→  message"
log_item() {
  printf '   %s→%s  %s\n' "$_LOG_CYAN" "$_LOG_RESET" "$*"
}

# Return the spinner character for frame $1 (0-indexed, cycles every 10)
_log_spinner_char() {
  case $(($1 % 10)) in
  0) printf '⠋' ;;
  1) printf '⠙' ;;
  2) printf '⠹' ;;
  3) printf '⠸' ;;
  4) printf '⠼' ;;
  5) printf '⠴' ;;
  6) printf '⠦' ;;
  7) printf '⠧' ;;
  8) printf '⠇' ;;
  9) printf '⠏' ;;
  esac
}

# Run a command with a spinner. Shows ✅ on success, ❌ + output on failure.
# Usage: log_task "label" command [args...]
log_task() {
  _lt_msg="$1"
  shift
  _lt_err=$(mktemp)

  if [ -t 1 ]; then
    (
      _i=0
      while true; do
        _c=$(_log_spinner_char "$_i")
        printf '\r   %s%s%s  %s...' "$_LOG_CYAN" "$_c" "$_LOG_RESET" "$_lt_msg"
        sleep 0.08
        _i=$((_i + 1))
      done
    ) &
    _lt_pid=$!

    if "$@" >"$_lt_err" 2>&1; then
      _lt_ok=1
    else
      _lt_ok=0
    fi

    kill "$_lt_pid" 2>/dev/null || true
    wait "$_lt_pid" 2>/dev/null || true
    printf '\r\033[K'
  else
    if "$@" >"$_lt_err" 2>&1; then
      _lt_ok=1
    else
      _lt_ok=0
    fi
  fi

  if [ "$_lt_ok" -eq 1 ]; then
    printf '   %s✅  %s%s\n' "$_LOG_GREEN" "$_lt_msg" "$_LOG_RESET"
    rm -f "$_lt_err"
  else
    printf '   %s❌  %s%s\n' "$_LOG_RED" "$_lt_msg" "$_LOG_RESET"
    cat "$_lt_err" >&2
    rm -f "$_lt_err"
    return 1
  fi
}
