# 🔧 Configuration

## 📁 Repository structure

```
profiles/
  <profile>/
    <platform>/
      [<user>/]             # optional per-user directory (when DOTFILES_USER is set)
        dotfiles/           # config files linked/rendered into the machine
        scripts/
          init.sh           # sets up the platform, creates .config.json from the example
          install.sh        # installs all dependencies (e.g. brew bundle)
          capture.sh        # captures installed packages back to the repo
          upgrade.sh        # upgrades all packages (e.g. brew upgrade)
          post-link.sh      # optional hook run after `configs link`
        services/           # Docker service definitions (homelab ops only)
          <category>/<service>/
        .config.example.json
        Brewfile
lib/                        # link, gather, unlock, format, verify
```

The active profile is selected by environment variables, exported by the linked `.zshrc`:

| Variable            | Example   | Notes                                             |
| ------------------- | --------- | ------------------------------------------------- |
| `DOTFILES_PROFILE`  | `work`    | Required                                          |
| `DOTFILES_PLATFORM` | `mac`     | Required                                          |
| `DOTFILES_USER`     | `ops`     | Optional; selects `profiles/<profile>/<platform>/<user>/` |

## 🔗 Symlinks vs templates

| File type                         | On `configs link`                                              | Syncing edits back                         |
| --------------------------------- | -------------------------------------------------------------- | ------------------------------------------ |
| Plain (e.g. `.zshrc`)             | Symlinked to the destination                                   | Automatic — the machine file *is* the repo file; just commit |
| Template (e.g. `.gitconfig.tmpl`) | Rendered with `envsubst`, written as a copy without `.tmpl`    | Run `dotfiles configs gather`              |
| Directory (e.g. `.karabiner/`)    | Symlinked as a whole; an existing real directory is moved to `<dest>.bak.<timestamp>` | Automatic; just commit |

## 📝 `.config.json`

Each profile has a gitignored `.config.json`, created by `make init` from `.config.example.json`:

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

- **`env`** — variables substituted into templates. Omit if the profile has no templates.
- **`paths`** — destination overrides. Files not listed land in `$HOME` under their own name.

## 🔐 Bitwarden secrets

An `env` value can reference a Bitwarden field instead of holding a plain string. Both can be mixed:

```json
{
  "env": {
    "GIT_CONFIG_NAME": "bw://GIT_CONFIG_NAME",
    "EDITOR": "vim"
  }
}
```

**Item convention:** one Bitwarden item (e.g. a Secure Note) named `dotfiles/<profile>/<platform>`, with each variable as a **custom field**. The item name is derived from `DOTFILES_PROFILE` and `DOTFILES_PLATFORM`; the `bw://` reference only names the field.

**Unlocking:** `configs link` and `configs gather` unlock the vault automatically when they meet a `bw://` reference and no valid session exists. To pre-unlock:

```sh
dotfiles configs unlock
```

This logs in if needed and saves the session to `.bw_session` (gitignored), which later commands reuse.

**Non-interactive (servers, CI):** set an API key first and `configs unlock` uses it automatically. Generate one in the Bitwarden web vault under **Settings → Security → Keys**.

```sh
export BW_CLIENTID=user.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export BW_CLIENTSECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
