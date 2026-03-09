#!/bin/sh

# shellcheck source=/dev/null
. "$(dirname "$0")/log.sh"

DOTFILES_PROFILE="$1"
DOTFILES_PLATFORM="$2"

printf '\n'
printf '%sdotfiles%s  — a personal machine configuration manager\n' "$_LOG_BOLD" "$_LOG_RESET"
printf '\n'
printf '%sUsage:%s  dotfiles %s<command>%s [DOTFILES_PROFILE=<profile>] [DOTFILES_PLATFORM=<platform>]\n' \
  "$_LOG_BOLD" "$_LOG_RESET" "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '%sCommands:%s\n' "$_LOG_BOLD" "$_LOG_RESET"
printf '\n'
printf '  %sinit%s       Set up a new machine:\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '               - installs platform dependencies (e.g. Homebrew)\n'
printf '               - creates .config.json from example\n'
printf '\n'
printf '  %sinstall%s    Install all profile packages (e.g. brew bundle)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %scapture%s    Capture installed packages back into the repository (e.g. Brewfile)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '  %slink%s       Render templates and symlink dotfiles into the machine\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sgather%s     Gather rendered dotfiles from the machine back into repository templates\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sunlock%s     Unlock Bitwarden vault for bw:// secret resolution\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '  %sformat%s     Auto-format all .sh and .json files in the repository\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sverify%s     Run shellcheck and format checks on all scripts and JSON files\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %stest%s       Run end-to-end tests for link and gather against the active profile\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %senv%s        Print current DOTFILES_PROFILE and DOTFILES_PLATFORM values\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %swhere%s      Print the absolute repository path\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %shelp%s       Show this help message\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '%sCurrent:%s  DOTFILES_PROFILE=%s%s%s  DOTFILES_PLATFORM=%s%s%s\n' \
  "$_LOG_BOLD" "$_LOG_RESET" \
  "$_LOG_GREEN" "$DOTFILES_PROFILE" "$_LOG_RESET" \
  "$_LOG_GREEN" "$DOTFILES_PLATFORM" "$_LOG_RESET"
printf '%sExample:%s  dotfiles link DOTFILES_PROFILE=homelab DOTFILES_PLATFORM=mac\n' \
  "$_LOG_DIM" "$_LOG_RESET"
printf '\n'
