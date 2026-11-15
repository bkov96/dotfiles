# 🍴 Forking

Use this repo as the base for your own machines. A fork is fully independent: your profiles, your dotfiles, your variables.

## 1. Fork and clone

Fork on GitHub, then:

```sh
git clone https://github.com/<you>/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
```

## 2. Update the CI badges

In `README.md`, replace `bkov96` with your GitHub username in the two badge lines.

## 3. Create your profile

Keep or delete the existing profiles, then add your own (`profiles/work/mac/` is a working example to copy):

```
profiles/<profile>/<platform>/
  .config.example.json  # template variables + destination paths
  dotfiles/             # your config files
  scripts/
    init.sh             # install package manager, create .config.json from the example
    install.sh          # install dependencies (e.g. brew bundle)
    capture.sh          # snapshot installed packages back to the repo
    upgrade.sh          # upgrade all packages
```

## 4. Fill in `.config.example.json`

Declare the template variables with empty values, and map any file that should not land in `$HOME`:

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

Your `init.sh` turns this into `.config.json`, filling values as plain strings or `bw://` references. How files, templates and secrets work: [Configuration](configuration.md).

## 5. Add your dotfiles

Put files in `dotfiles/`. Plain files are symlinked; files ending in `.tmpl` are rendered with the `env` values.

Make your `.zshrc` export the profile variables so later sessions pick them up:

```sh
export DOTFILES_PROFILE=<profile>
export DOTFILES_PLATFORM=<platform>
```

**Multiple users on one machine?** Also export `DOTFILES_USER=<user>`. The profile directory becomes `profiles/<profile>/<platform>/<user>/`, each user with their own `dotfiles/`, `scripts/`, `.config.example.json` and `Brewfile` (see `profiles/homelab/mac/`).

## 6. Check the CI profile

Both workflows in `.github/workflows/` run against the `github/ci` profile:

```yaml
env:
  DOTFILES_PROFILE: github
  DOTFILES_PLATFORM: ci
```

Keep it as a minimal test harness, or replace it with your own. If your templates use variables beyond `GIT_CONFIG_NAME` / `GIT_CONFIG_EMAIL`, declare them in the CI profile's `.config.example.json`.

## 7. Bootstrap

Follow [Bootstrap](bootstrap.md) with your profile and platform names.
