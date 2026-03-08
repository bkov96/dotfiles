# Dotfiles management

export DOTFILES_PROFILE="work"
export DOTFILES_PLATFORM="mac"

dotfiles() {
  make -C ~/repos/dotfiles "$@"
}

# User-defined aliases

alias ll="ls -l"

source $(brew --prefix nvm)/nvm.sh

export PATH="/opt/homebrew/opt/kubelogin:/opt/homebrew/opt/dotnet@8/bin:$PATH"
export PATH="$HOME/.dotnet/tools:$PATH"
