# 🍴 Forking this repo

This repo is designed to be forked. Each fork is fully independent — you bring your own profiles, dotfiles, and environment variables. Here's how to set it up from scratch.

## Contents

- [1. Fork and clone](#1-fork-and-clone)
- [2. Update CI badge URLs](#2-update-ci-badge-urls)
- [3. Set up your profile](#3-set-up-your-profile)
- [4. Export environment variables](#4-export-environment-variables)
- [5. Update GitHub Actions](#5-update-github-actions)
- [6. Bootstrap](#6-bootstrap)

## 1. Fork and clone

Fork the repo on GitHub, then clone your fork:

```sh
git clone https://github.com/<you>/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
```

## 2. Update CI badge URLs

`README.md` contains two badge URLs pointing to `bkov96/dotfiles`. Replace `bkov96` with your GitHub username in both lines:

```md
[![verify](https://github.com/<you>/dotfiles/actions/workflows/verify.yml/badge.svg)](https://github.com/<you>/dotfiles/actions/workflows/verify.yml)
[![test](https://github.com/<you>/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/<you>/dotfiles/actions/workflows/test.yml)
```

## 3. Set up your profile

Delete or keep the existing profiles under `profiles/`. Create your own:

```
profiles/<profile>/<platform>/
  .config.example.json  # env vars and path overrides for individual dotfiles
  dotfiles/             # your config files
  setup/
    init.sh             # bootstrap: install package manager, copy example files
    install.sh          # install dependencies (e.g. brew bundle)
    capture.sh          # snapshot installed state back to the repo
    upgrade.sh          # upgrade all packages (e.g. brew upgrade)
```

**`.config.example.json`** — Declares template variables and maps dotfile names to target paths. Files not listed in `paths` default to `$HOME`. The `env` section can be omitted if no templates are used:

```json
{
  "env": {
    "GIT_CONFIG_NAME": "",
    "GIT_CONFIG_EMAIL": ""
  },
  "paths": {
    ".gitconfig.tmpl": "~/.gitconfig"
  }
}
```

Keep values empty in the example. Your `init.sh` can populate them — either as plain strings or as `bw://` references for Bitwarden-backed secrets (see the `work/mac` profile for an example).

**`dotfiles/`** — Plain files (e.g. `.zshrc`) are symlinked into the destination. Files ending in `.tmpl` (e.g. `.gitconfig.tmpl`) are rendered with `envsubst` using values from the `"env"` section of `.config.json` and written as copies (without the `.tmpl` suffix). Values can be plain strings or `bw://` references resolved at link time.

**`setup/` scripts** — `init.sh` runs first: install prerequisites and copy example files to their live versions. `install.sh` installs packages. `capture.sh` snapshots installed state back into the repo. `upgrade.sh` upgrades all installed packages.

See `profiles/work/mac/` for a working example.

## 4. Export environment variables

Two variables must be set in every shell session. The easiest place is your `.zshrc`. Since `.zshrc` itself lives in `dotfiles/`, this is a chicken-and-egg on a fresh machine — export them once for the session before running any `make` commands:

```sh
export DOTFILES_PROFILE=<profile>
export DOTFILES_PLATFORM=<platform>

make init
```

After `make configs-link`, your `.zshrc` is live and exports the vars automatically for every subsequent session.

## 5. Update GitHub Actions

Both workflow files reference the profile to use for CI:

```yaml
# .github/workflows/verify.yml and test.yml
env:
  DOTFILES_PROFILE: github
  DOTFILES_PLATFORM: ci
```

You can keep the `github/ci` profile as a minimal test harness (it has its own `.config.example.json` with safe test values), or replace it with your own CI profile. If your templates use variables beyond `GIT_CONFIG_NAME` / `GIT_CONFIG_EMAIL`, make sure they're declared in the CI profile's `.config.example.json` `"env"` section.

## 6. Bootstrap

Follow the full bootstrap guide: [docs/bootstrap.md](bootstrap.md)

---

Back to [README](../README.md)
