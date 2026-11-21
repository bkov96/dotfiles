# 🧑‍💻 Personal Mac setup

Setup of the `personal/mac` profile on a fresh macOS install: shell and terminal ([Terminal](../../shared/terminal.md)), git, homelab SSH, and a .NET + Expo dev stack.

## ✅ Prerequisites

A Bitwarden item named `dotfiles/personal/mac` with these custom fields:

| Field                   | Value                                                        |
| ----------------------- | ------------------------------------------------------------ |
| `GIT_CONFIG_NAME`       | Git author name                                              |
| `GIT_CONFIG_EMAIL`      | Git author email                                             |
| `HOMELAB_HOST`          | Homelab hostname or IP (for `homelab-admin` / `homelab-ops`) |
| `SSH_PRIVATE_KEY_B64`   | base64 of `~/.ssh/id_ed25519_homelab`                        |
| `SSH_PUBLIC_KEY_B64`    | base64 of `~/.ssh/id_ed25519_homelab.pub`                    |
| `GITHUB_PACKAGES_USER`  | GitHub Packages username (exported in `.zshrc`)              |
| `GITHUB_PACKAGES_TOKEN` | GitHub Packages token (exported in `.zshrc`)                 |

No homelab key pair yet? Generate and encode it:

```sh
ssh-keygen -t ed25519 -C "homelab" -f ~/.ssh/id_ed25519_homelab
base64 -i ~/.ssh/id_ed25519_homelab | tr -d '\n'       # → SSH_PRIVATE_KEY_B64
base64 -i ~/.ssh/id_ed25519_homelab.pub | tr -d '\n'   # → SSH_PUBLIC_KEY_B64
```

## 🚀 Steps

```sh
xcode-select --install
git clone https://github.com/bkov96/dotfiles.git ~/repos/dotfiles && cd ~/repos/dotfiles
export DOTFILES_PROFILE=personal DOTFILES_PLATFORM=mac

make init               # Homebrew + .config.json
make packages-install   # brew bundle (sign in to the App Store first for mas apps)
make configs-link       # render templates, symlink dotfiles, decode SSH keys
```

## 🔁 Day to day

| Task                                   | Command                                     |
| -------------------------------------- | ------------------------------------------- |
| Installed or removed a brew package    | `dfs packages capture`, then commit         |
| Upgrade everything                     | `dfs packages upgrade`                      |
| Changed a `.tmpl` in the repo          | `dfs configs link`, then `exec zsh`         |
| Edited a rendered file on the machine  | `dfs configs gather`, then commit           |
| Edited a symlinked file                | Just commit                                 |

## ⌨️ Karabiner-Elements

`~/.config/karabiner` is a symlink to `profiles/personal/mac/dotfiles/.karabiner/`. The whole directory is linked, not just `karabiner.json`, because Karabiner replaces the file on save, which would break a file symlink. Changes made in the Karabiner UI land in the repo, so just commit them.

The tracked rule adapts the Hungarian input source to the US (ANSI) MacBook keyboard. It only applies while a Hungarian input source is active:

| Key        | Types |
| ---------- | ----- |
| `` ` ``    | `0`   |
| `Ctrl+Z`   | `í`   |

On first launch, grant Karabiner the Input Monitoring permission and enable its driver extension when macOS asks.
