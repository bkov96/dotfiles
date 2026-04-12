#!/bin/sh

# shellcheck source=/dev/null
. "$(dirname "$0")/log.sh"

DOTFILES_PROFILE="$1"
DOTFILES_PLATFORM="$2"
DOTFILES_USER="$3"

printf '\n'
printf '%sdotfiles%s  — a personal machine configuration manager\n' "$_LOG_BOLD" "$_LOG_RESET"
printf '\n'
printf '%sUsage:%s  dotfiles %s<group> <action>%s [DOTFILES_PROFILE=<profile>] [DOTFILES_PLATFORM=<platform>]\n' \
  "$_LOG_BOLD" "$_LOG_RESET" "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '%sPackages%s\n\n' "$_LOG_BOLD" "$_LOG_RESET"
printf '  %spackages install%s    Install all profile packages (e.g. brew bundle)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %spackages capture%s    Capture installed packages back into the repository\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %spackages upgrade%s    Upgrade all profile packages (e.g. brew upgrade)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '%sConfigs%s\n\n' "$_LOG_BOLD" "$_LOG_RESET"
printf '  %sconfigs link%s        Render templates and symlink dotfiles into the machine\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sconfigs gather%s      Gather rendered dotfiles from the machine back into templates\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sconfigs unlock%s      Unlock Bitwarden vault for bw:// secret resolution\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '%sScripts%s\n\n' "$_LOG_BOLD" "$_LOG_RESET"
printf '  %sscripts format%s      Auto-format all .sh and .json files in the repository\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sscripts verify%s      Run shellcheck and format checks on all scripts and JSON files\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sscripts test%s        Run end-to-end tests for link and gather\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '%sRepo%s\n\n' "$_LOG_BOLD" "$_LOG_RESET"
printf '  %srepo where%s          Print the absolute repository path\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %srepo cd%s             cd into the repository directory\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %srepo diff%s           Print git diff for the repository\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '%sServices%s\n\n' "$_LOG_BOLD" "$_LOG_RESET"
printf '  %sservices list%s        List all services and their status\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sservices init%s        Initialize a service (or all services)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sservices start%s       Start a service (or all services)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sservices stop%s        Stop a service (or all services)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sservices restart%s     Restart a service (or all services)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %sservices status%s      Show detailed status of a service (or all)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '%sStandalone%s\n\n' "$_LOG_BOLD" "$_LOG_RESET"
printf '  %sinit%s                Set up a new machine (install dependencies, create .config.json)\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %senv%s                 Print current DOTFILES_PROFILE and DOTFILES_PLATFORM values\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '  %shelp%s                Show this help message\n' "$_LOG_CYAN" "$_LOG_RESET"
printf '\n'
printf '%sCurrent:%s  DOTFILES_PROFILE=%s%s%s  DOTFILES_PLATFORM=%s%s%s' \
  "$_LOG_BOLD" "$_LOG_RESET" \
  "$_LOG_GREEN" "$DOTFILES_PROFILE" "$_LOG_RESET" \
  "$_LOG_GREEN" "$DOTFILES_PLATFORM" "$_LOG_RESET"
if [ -n "$DOTFILES_USER" ]; then
  printf '  DOTFILES_USER=%s%s%s' "$_LOG_GREEN" "$DOTFILES_USER" "$_LOG_RESET"
fi
printf '\n'
printf '%sExample:%s  dotfiles configs link DOTFILES_PROFILE=homelab DOTFILES_PLATFORM=mac DOTFILES_USER=ops\n' \
  "$_LOG_DIM" "$_LOG_RESET"
printf '\n'
