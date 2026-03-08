# 🏠 dotfiles

[![verify](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml/badge.svg)](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml)

Personal machine configuration, organized by environment and platform. Dotfiles are symlinked into `$HOME`, with template files rendered using `envsubst` to inject personal values like name and email.

## 📁 Structure

```
environments/
  <env>/
    <platform>/
      dotfiles/             # config files to be linked/rendered into $HOME
      setup/
        init.sh             # sets up the platform and creates .env / .config.json
        install.sh          # installs all dependencies (e.g. brew bundle)
      .env.example          # required environment variables (copy to .env and fill in)
      .config.example.json  # optional path overrides (copy to .config.json to customize)
      ...                   # platform-specific files (e.g. Brewfile on macOS)
```

Currently available environments: `work/mac`, `homelab/mac`.

### How it works

- **Plain dotfiles** (e.g. `.zshrc`) are symlinked directly into `$HOME`
- **Template files** (e.g. `.gitconfig.tmpl`) are rendered with `envsubst` using variables from `.env`, and written to `$HOME` (without the `.tmpl` suffix)
- By default all files land in `$HOME`. Override individual destinations via `.config.json`

> 💡 **No reverse sync needed for symlinked files.** Because plain dotfiles are symlinks, any edits you make directly on the machine (e.g. tweaking `.zshrc`) are instantly reflected in this repo — just `git add` and commit as usual. Template files (`.tmpl`) are rendered as copies, so edits to e.g. `~/.gitconfig` on the machine won't sync back automatically — use `make gather` to pull them back into the repo.

---

## 📦 Commands

Commands come in pairs — one direction pushes from the repo to the machine, the other pulls state back.

| Command   | Description                                                                                          |
| --------- | ---------------------------------------------------------------------------------------------------- |
| `init`    | Set up a new machine: install platform dependencies and create `.env` / `.config.json` from examples |
|           |                                                                                                      |
| `install` | Install all environment packages (e.g. `brew bundle`)                                                |
| `capture` | Capture installed packages back into the repository (e.g. `Brewfile`)                                |
|           |                                                                                                      |
| `link`    | Render templates and symlink dotfiles into the machine                                               |
| `gather`  | Gather rendered dotfiles from the machine back into repository templates                             |
|           |                                                                                                      |
| `format`  | Auto-format all `.sh` and `.json` files in the repository                                            |
| `verify`  | Run shellcheck and format checks on all scripts and JSON files                                       |
| `env`     | Print current `DOTFILES_ENV` and `DOTFILES_PLATFORM` values                                          |
| `where`   | Print the absolute repository path                                                                   |
| `help`    | Show the help message                                                                                |

All commands accept `DOTFILES_ENV` and `DOTFILES_PLATFORM` overrides:

```sh
make capture DOTFILES_ENV=homelab DOTFILES_PLATFORM=mac
```

---

## 🚀 Bootstrap a new machine on macOS (e.g. `work/mac`)

You only need two things to get started: `git` and `make`. On macOS, both ship with Xcode Command Line Tools.

### 1. Install Xcode Command Line Tools

```sh
xcode-select --install
```

### 2. Clone this repo

```sh
git clone https://github.com/bkov96/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
```

### 3. Initialize the environment

```sh
make init
```

This installs Homebrew (if missing), then creates `.env` and `.config.json` from the example files. If Xcode CLT or Homebrew need a manual step to complete, the script will tell you — just re-run `make init` afterwards.

### 4. Fill in your `.env`

Open `environments/work/mac/.env` and set your values:

```sh
GIT_CONFIG_NAME=Jane Doe
GIT_CONFIG_EMAIL=jane@example.com
```

### 5. Install dependencies

```sh
make install
```

Runs `brew bundle` to install all packages from the Brewfile.

### 6. Link dotfiles

```sh
make link
```

That's it — your dotfiles are live. 🎉

> 💡 After `make link`, a `dotfiles` shell function is available in every new terminal. You can use it from anywhere instead of navigating to the repo:

> ```sh
> dotfiles link
> dotfiles gather DOTFILES_ENV=homelab DOTFILES_PLATFORM=mac
> ```

---

## ⚙️ Customizing paths

By default every file in `dotfiles/` lands in `$HOME`. To put a file somewhere else, create a `.config.json` from the example:

```sh
cp environments/<env>/<platform>/.config.example.json environments/<env>/<platform>/.config.json
```

Then override only the paths you care about — everything else is still auto-discovered:

```json
{
  "paths": {
    ".gitconfig.tmpl": "~/.gitconfig",
    ".zshrc": "/some/other/path/.zshrc"
  }
}
```

Both `.env` and `.config.json` are gitignored and never committed.
