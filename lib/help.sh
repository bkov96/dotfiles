#!/bin/sh

ENV="$1"
PLATFORM="$2"

echo "Usage: dotfiles <command> [ENV=<env>] [PLATFORM=<platform>]"
echo ""
echo "Commands:"
echo "  init      Set up a new machine: installs platform dependencies (e.g. Homebrew),"
echo "            and creates .env and .config.json from examples"
echo "  install   Install all environment packages (e.g. brew bundle)"
echo "  link      Render templates and symlink dotfiles into \$HOME"
echo "  format    Auto-format all .sh and .json files in the repository"
echo "  verify    Run shellcheck and format checks on all scripts and JSON files in the repository"
echo "  help      Show this help message"
echo ""
echo "Defaults: ENV=$ENV, PLATFORM=$PLATFORM"
echo "Example:  dotfiles link ENV=homelab PLATFORM=mac"
