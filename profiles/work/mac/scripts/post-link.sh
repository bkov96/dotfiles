#!/bin/sh
set -e

# shellcheck disable=SC2034
PROFILE_DIR="$1"

# shellcheck source=/dev/null
. "$(dirname "$0")/../../../../lib/log.sh"

log_header "Running post-link for ${DOTFILES_PROFILE:-}/${DOTFILES_PLATFORM:-}..."

# Seed k9s skin selection once; k9s owns config.yaml afterward (it's stateful).
K9S_CFG="$HOME/.config/k9s/config.yaml"
if [ ! -f "$K9S_CFG" ]; then
  mkdir -p "$(dirname "$K9S_CFG")"
  cat >"$K9S_CFG" <<'YAML'
k9s:
  ui:
    skin: ghostty
YAML
  log_ok "Seeded k9s skin (ghostty) in $K9S_CFG"
fi

log_done
