# 🏠 dotfiles

[![verify](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml/badge.svg)](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml)
[![test](https://github.com/bkov96/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/bkov96/dotfiles/actions/workflows/test.yml)

## 🎯 What

A machine configuration manager, organized by profile and platform. One repo holds the dotfiles, package lists, setup scripts and Docker services for each machine:

| Profile       | Machine                                                  |
| ------------- | -------------------------------------------------------- |
| `work/mac`    | Work laptop: shell, terminal, git, SSH, CLI tools        |
| `homelab/mac` | Headless Mac Mini server (`admin` and `ops` users) and its services |
| `github/ci`   | Minimal profile used by the CI tests                     |

## 💡 Why

Every config, dotfile and installed package is tracked in git, so any machine — including the whole homelab — can be rebuilt from a clean install. Secrets stay in Bitwarden and never enter the repo.

## 🔧 How

- **Plain dotfiles** are symlinked into place, so edits on the machine are edits in the repo.
- **Templates** (`*.tmpl`) are rendered with `envsubst`, using values from a gitignored `.config.json` that can point at Bitwarden (`bw://FIELD`).
- **Packages** are installed from, and captured back into, a `Brewfile`.
- **Services** (homelab) are Docker Compose templates behind a Caddy reverse proxy.

Setting up a machine takes a few commands:

```sh
xcode-select --install
git clone https://github.com/bkov96/dotfiles.git ~/repos/dotfiles && cd ~/repos/dotfiles
export DOTFILES_PROFILE=work DOTFILES_PLATFORM=mac

make init               # Homebrew + .config.json
make packages-install   # brew bundle
make configs-link       # render templates, symlink dotfiles
```

After that, a `dotfiles` shell function (alias `dfs`) is available everywhere: `dfs packages capture`, `dfs configs link`, `dfs services start`.

## 📚 Docs

Full documentation lives in [docs/](docs/README.md).

| I want to…                         | Read                                                      |
| ---------------------------------- | --------------------------------------------------------- |
| Set up the work Mac                | [Work setup](docs/profiles/work/setup.md)                 |
| Rebuild the homelab                | [Homelab setup](docs/profiles/homelab/setup.md)           |
| Use this repo for my own machines  | [Forking](docs/general/forking.md)                        |
| Look up a command                  | [Commands](docs/general/commands.md)                      |
| Understand configs and secrets     | [Configuration](docs/general/configuration.md)            |
