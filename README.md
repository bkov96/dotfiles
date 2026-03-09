# 🏠 dotfiles

[![verify](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml/badge.svg)](https://github.com/bkov96/dotfiles/actions/workflows/verify.yml)
[![test](https://github.com/bkov96/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/bkov96/dotfiles/actions/workflows/test.yml)

Personal machine configuration, organized by profile and platform. Dotfiles are symlinked into `$HOME`, with template files rendered using `envsubst` to inject personal values like name and email.

## Contents

- [Structure](#-structure)
- [Commands](#-commands)
- [Bootstrap a new machine](#-bootstrap-a-new-machine)
- [Customizing paths](#️-customizing-paths)
- [Bitwarden secrets](#-using-bitwarden-for-secrets)
- [Forking](#-forking)
- [What's next](#-whats-next)

## 📁 Structure

```
profiles/
  <profile>/
    <platform>/
      dotfiles/             # config files to be linked/rendered into $HOME
      setup/
        init.sh             # sets up the platform and creates .config.json from example
        install.sh          # installs all dependencies (e.g. brew bundle)
      .config.example.json  # env vars and path overrides (copy to .config.json and fill in)
      ...                   # platform-specific files (e.g. Brewfile on macOS)
```

Currently available profiles: `work/mac`, `homelab/mac`, `github/ci` (CI only).

### How it works

- **Plain dotfiles** (e.g. `.zshrc`) are symlinked directly into `$HOME`
- **Template files** (e.g. `.gitconfig.tmpl`) are rendered with `envsubst` using variables from the `env` section of `.config.json`, and written to `$HOME` (without the `.tmpl` suffix)
- By default all files land in `$HOME`. Override individual destinations via `.config.json`

> 💡 **No reverse sync needed for symlinked files.** Because plain dotfiles are symlinks, any edits you make directly on the machine (e.g. tweaking `.zshrc`) are instantly reflected in this repo — just `git add` and commit as usual. Template files (`.tmpl`) are rendered as copies, so edits to e.g. `~/.gitconfig` on the machine won't sync back automatically — use `make gather` to pull them back into the repo.

---

## 📦 Commands

| Command   | Description                                                                                |
| --------- | ------------------------------------------------------------------------------------------ |
| `init`    | Set up a new machine: install platform dependencies and create `.config.json` from example |
|           |                                                                                            |
| `install` | Install all profile packages (e.g. `brew bundle`)                                          |
| `capture` | Capture installed packages back into the repository (e.g. `Brewfile`)                      |
|           |                                                                                            |
| `link`    | Render templates and symlink dotfiles into the machine                                     |
| `gather`  | Gather rendered dotfiles from the machine back into repository templates                   |
| `unlock`  | Unlock Bitwarden vault for `bw://` secret resolution (runs automatically during `link` and `gather` when needed) |
|           |                                                                                            |
| `format`  | Auto-format all `.sh` and `.json` files in the repository                                  |
| `verify`  | Run shellcheck and format checks on all scripts and JSON files                             |
| `test`    | Run end-to-end tests for `link` and `gather` against the active profile's test fixtures    |
| `env`     | Print current `DOTFILES_PROFILE` and `DOTFILES_PLATFORM` values                            |
| `where`   | Print the absolute repository path                                                         |
| `help`    | Show the help message                                                                      |

All commands accept `DOTFILES_PROFILE` and `DOTFILES_PLATFORM` overrides:

```sh
make capture DOTFILES_PROFILE=homelab DOTFILES_PLATFORM=mac
```

---

## 🚀 Bootstrap a new machine

See [docs/bootstrap.md](docs/bootstrap.md) for step-by-step macOS setup instructions.

---

## ⚙️ Customizing paths

By default every file in `dotfiles/` lands in `$HOME`. To put a file somewhere else, create a `.config.json` from the example:

```sh
cp profiles/<profile>/<platform>/.config.example.json profiles/<profile>/<platform>/.config.json
```

Then override only the paths you care about — everything else is still auto-discovered:

```json
{
  "env": {
    "GIT_CONFIG_NAME": "Jane Doe",
    "GIT_CONFIG_EMAIL": "jane@example.com"
  },
  "paths": {
    ".gitconfig.tmpl": "~/.gitconfig",
    ".zshrc": "/some/other/path/.zshrc"
  }
}
```

`.config.json` is gitignored and never committed.

---

## 🔐 Using Bitwarden for secrets

Instead of plain strings, env values in `.config.json` can reference secrets stored in Bitwarden using a `bw://` prefix:

```json
{
  "env": {
    "GIT_CONFIG_NAME": "bw://GIT_CONFIG_NAME",
    "GIT_CONFIG_EMAIL": "bw://GIT_CONFIG_EMAIL",
    "EDITOR": "vim"
  }
}
```

Plain values and `bw://` references can be mixed freely.

### Bitwarden item convention

Create one Bitwarden item named `dotfiles/<profile>/<platform>` (e.g. a Note called `dotfiles/work/mac`) with each variable as a **custom field**. The item name is derived automatically from `DOTFILES_PROFILE` and `DOTFILES_PLATFORM` — the `bw://` reference only needs the field name.

### Unlocking the vault

`make link` and `make gather` automatically unlock the vault when they encounter `bw://` references and no valid session exists — you don't need to run anything beforehand.

To pre-unlock (e.g. to verify vault access or avoid an interactive prompt mid-run), run:

```sh
make unlock
```

This handles login (if not already logged in) and unlocks the vault, saving the session to `.bw_session` (gitignored). Subsequent `make link` and `make gather` calls read it automatically.

For non-interactive environments (servers, CI), set `BW_CLIENTID` and `BW_CLIENTSECRET` before running — `make unlock` will use API key auth automatically. You can generate an API key in the Bitwarden web vault under **Settings → Security → Keys**.

---

## 🍴 Forking

Want to use this structure for your own machines? See [docs/forking.md](docs/forking.md).

---

## 🔭 What's next

See [docs/homelab.md](docs/homelab.md) for guidelines on expanding this repo into a homelab setup with multi-user environments and Docker-based services.
