# 🚀 Bootstrap a new macOS machine

The generic flow for any profile. Profile-specific runbooks: [work](../profiles/work/setup.md), [homelab](../profiles/homelab/setup.md).

You only need `git` and `make`; both ship with Xcode Command Line Tools.

## 1. Install Xcode Command Line Tools

```sh
xcode-select --install
```

## 2. Clone the repo

```sh
git clone https://github.com/bkov96/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
```

## 3. Select the profile

Your `.zshrc` isn't linked yet, so export the variables once for this session:

```sh
export DOTFILES_PROFILE=work
export DOTFILES_PLATFORM=mac
```

## 4. Initialize

```sh
make init
```

Installs Homebrew if missing and creates `.config.json` from the example, with `bw://` references pre-filled. If Xcode CLT or Homebrew need a manual step, the script says so — re-run `make init` afterwards.

## 5. Install packages

```sh
make packages-install
```

Runs `brew bundle` on the profile's Brewfile (includes the Bitwarden CLI).

## 6. Unlock Bitwarden (optional)

`make configs-link` unlocks the vault on demand. Run this first only to verify access or avoid a prompt mid-run:

```sh
make configs-unlock
```

Not using Bitwarden? Put plain values in the `env` section of `.config.json` instead. Details and non-interactive auth: [Configuration](configuration.md#-bitwarden-secrets).

## 7. Link dotfiles

```sh
make configs-link
```

Done. Open a new terminal: `.zshrc` now exports the profile variables and provides the `dotfiles` function (alias `dfs`), usable from any directory. See [Commands](commands.md).
