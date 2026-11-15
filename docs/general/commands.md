# 🧰 Commands

Usage: `dotfiles <group> <action>`. `dfs` is an alias for `dotfiles`.

The `dotfiles` shell function exists once `.zshrc` is linked. Before that (or in CI), use the equivalent make target from the repo root: `make <group>-<action>`, e.g. `make configs-link`.

## 🍺 Packages

| Command            | Description                                         |
| ------------------ | --------------------------------------------------- |
| `packages install` | Install all profile packages (`brew bundle`)        |
| `packages capture` | Capture installed packages back into the repository |
| `packages upgrade` | Upgrade all profile packages (`brew upgrade`)       |

## 🔗 Configs

| Command          | Description                                                   |
| ---------------- | ------------------------------------------------------------- |
| `configs link`   | Render templates and symlink dotfiles into the machine        |
| `configs gather` | Gather rendered dotfiles from the machine back into templates |
| `configs unlock` | Unlock the Bitwarden vault for `bw://` secret resolution      |

## 🐳 Services (homelab ops only)

| Command                  | Description                                    |
| ------------------------ | ---------------------------------------------- |
| `services list`          | Show all services and their status             |
| `services init [name]`   | Initialize all or a specific service           |
| `services start [name]`  | Start all or a specific service (ordered)      |
| `services stop [name]`   | Stop all or a specific service (reverse order) |
| `services restart name`  | Restart a specific service                     |
| `services status [name]` | Show detailed container status                 |

See [Homelab services](../profiles/homelab/services.md).

## 📜 Scripts

| Command          | Description                                                    |
| ---------------- | -------------------------------------------------------------- |
| `scripts format` | Auto-format all `.sh` and `.json` files in the repository      |
| `scripts verify` | Run shellcheck and format checks on all scripts and JSON files |
| `scripts test`   | Run end-to-end tests for `link` and `gather`                   |

## 📁 Repo

| Command      | Description                        |
| ------------ | ---------------------------------- |
| `repo where` | Print the absolute repository path |
| `repo cd`    | cd into the repository directory   |
| `repo diff`  | Print git diff for the repository  |

## ⭐ Standalone

| Command | Description                                                          |
| ------- | -------------------------------------------------------------------- |
| `init`  | Set up a new machine: install dependencies and create `.config.json` |
| `env`   | Print the current `DOTFILES_PROFILE` / `DOTFILES_PLATFORM` / `DOTFILES_USER` |
| `help`  | Show the help message                                                |

## 🎯 Targeting another profile

Every command accepts overrides:

```sh
dotfiles packages capture DOTFILES_PROFILE=homelab DOTFILES_PLATFORM=mac DOTFILES_USER=ops
```
