# Dotfiles management

export DOTFILES_PROFILE="homelab"
export DOTFILES_PLATFORM="mac"
export DOTFILES_USER="ops"

dotfiles() {
  local repo=~/repos/dotfiles

  case "$1" in
    packages|configs|scripts|repo)
      local group="$1" action="$2"
      shift 2 2>/dev/null

      if [ -z "$action" ]; then
        echo "Usage: dotfiles $group <action>" >&2
        return 1
      fi

      if [ "$group" = "repo" ] && [ "$action" = "cd" ]; then
        cd "$repo" || return 1
        return 0
      fi

      make -C "$repo" "${group}-${action}" "$@"
      ;;
    services)
      local action="$2" service="$3"

      if [ -z "$action" ]; then
        echo "Usage: dotfiles services <action> [service_name]" >&2
        return 1
      fi

      make -C "$repo" "services-${action}" SERVICE_NAME="${service:-}"
      ;;
    init|env|help)
      local cmd="$1"
      shift
      make -C "$repo" "$cmd" "$@"
      ;;
    "")
      make -C "$repo" help
      ;;
    *)
      echo "Unknown command: $1. Run 'dotfiles help' for usage." >&2
      return 1
      ;;
  esac
}

# Aliases

alias ll="ls -l"
alias dfs="dotfiles"
