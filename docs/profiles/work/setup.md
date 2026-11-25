# 💼 Work Mac setup

Step-by-step setup of the `work/mac` profile on a fresh macOS install. What the terminal then gives you is described in [Terminal](../../shared/terminal.md) and [Kubernetes / Azure](kubernetes.md).

## ✅ Prerequisites

A Bitwarden item named `dotfiles/work/mac` with these custom fields:

| Field                   | Value                                                        |
| ----------------------- | ------------------------------------------------------------ |
| `GIT_CONFIG_NAME`       | Git author name                                              |
| `GIT_CONFIG_EMAIL`      | Git author email                                             |
| `GITHUB_PACKAGES_USER`  | GitHub Packages username (exported in `.zshrc`)              |
| `GITHUB_PACKAGES_TOKEN` | GitHub Packages token (exported in `.zshrc`)                 |

## 🚀 Steps

### 1. Install Xcode Command Line Tools

```sh
xcode-select --install
```

### 2. Clone the repo

The `dotfiles` shell function expects this exact path.

```sh
git clone https://github.com/bkov96/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
```

### 3. Initialize

```sh
export DOTFILES_PROFILE=work DOTFILES_PLATFORM=mac
make init
```

Installs Homebrew and creates `.config.json` with `bw://` references. If it stops for a manual Xcode or Homebrew step, finish that and re-run.

### 4. Install packages

```sh
make packages-install
```

### 5. Link configs

```sh
make configs-link
```

Prompts for the Bitwarden master password, then renders and links everything:

| Repo file (`dotfiles/`)             | Destination                         |
| ----------------------------------- | ----------------------------------- |
| `.zshrc.tmpl`                       | `~/.zshrc`                          |
| `.gitconfig.tmpl`                   | `~/.gitconfig`                      |
| `.ssh_config.tmpl`                  | `~/.ssh/config`                     |
| `.ghostty_config`                   | `~/.config/ghostty/config`          |
| `.starship.toml`                    | `~/.config/starship.toml`           |
| `.atuin.toml`                       | `~/.config/atuin/config.toml`       |
| `.k9s_skin.yaml`                    | `~/.config/k9s/skins/ghostty.yaml`  |
| `.zsh_shift_select.zsh`             | `~/.config/zsh/shift-select.zsh`    |

A post-link hook then seeds `~/.config/k9s/config.yaml` with the `ghostty` skin if the file doesn't exist.

### 6. Manual macOS steps

- **Window restore:** System Settings → Desktop & Dock → **"Close windows when quitting an application" = OFF**. Otherwise Ghostty can't restore tabs and splits.
- **Default terminal:** macOS has no global setting for this — pin Ghostty to the Dock.

### 7. Verify

Open a new Ghostty window, then:

```sh
dfs env               # work / mac
```

## 🔁 Day to day

| Task                                   | Command                                     |
| -------------------------------------- | ------------------------------------------- |
| Installed or removed a brew package    | `dfs packages capture`, then commit         |
| Upgrade everything                     | `dfs packages upgrade`                      |
| Changed a `.tmpl` in the repo          | `dfs configs link`, then `exec zsh`         |
| Edited a rendered file on the machine  | `dfs configs gather`, then commit           |
| Edited a symlinked file                | Just commit                                 |
