# 🚀 Bootstrap a new machine on macOS

You only need two things to get started: `git` and `make`. On macOS, both ship with Xcode Command Line Tools.

## Contents

- [1. Install Xcode Command Line Tools](#1-install-xcode-command-line-tools)
- [2. Clone this repo](#2-clone-this-repo)
- [3. Initialize the profile](#3-initialize-the-profile)
- [4. Install dependencies](#4-install-dependencies)
- [5. Unlock Bitwarden](#5-unlock-bitwarden)
- [6. Link dotfiles](#6-link-dotfiles)

## 1. Install Xcode Command Line Tools

```sh
xcode-select --install
```

## 2. Clone this repo

```sh
git clone https://github.com/bkov96/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
```

## 3. Initialize the profile

`make` needs to know which profile and platform to use. On a fresh machine your `.zshrc` isn't linked yet, so export them once for the session:

```sh
export DOTFILES_PROFILE=work
export DOTFILES_PLATFORM=mac
```

Then run:

```sh
make init
```

This installs Homebrew (if missing), then creates `.config.json` from the example with `bw://` references pre-filled. If Xcode CLT or Homebrew need a manual step to complete, the script will tell you — just re-run `make init` afterwards.

## 4. Install dependencies

```sh
make packages-install
```

Runs `brew bundle` to install all packages from the Brewfile, including the Bitwarden CLI.

## 5. Unlock Bitwarden (optional)

`dotfiles configs link` will unlock the vault automatically when it encounters `bw://` references. You can skip this step and let it prompt you during `dotfiles configs link`.

Run this first if you want to verify vault access upfront, or to avoid an interactive prompt mid-run:

```sh
make configs-unlock
```

This logs in to Bitwarden (if needed) and unlocks the vault, saving the session to `.bw_session` (gitignored). You only need to run this once per shell session.

For non-interactive environments (e.g. servers), set `BW_CLIENTID` and `BW_CLIENTSECRET` before running — `make configs-unlock` will use API key auth automatically:

```sh
export BW_CLIENTID=user.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export BW_CLIENTSECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxx

make configs-unlock
```

If you prefer not to use Bitwarden, set plain values directly in the `"env"` section of `.config.json` instead.

## 6. Link dotfiles

```sh
make configs-link
```

That's it — your dotfiles are live. Your `.zshrc` now exports `DOTFILES_PROFILE` and `DOTFILES_PLATFORM` automatically, so you won't need to export them manually in future sessions.

> After `make configs-link`, a `dotfiles` shell function is available in every new terminal. You can use it from anywhere instead of navigating to the repo:

> ```sh
> dotfiles configs link
> dotfiles configs gather DOTFILES_PROFILE=homelab DOTFILES_PLATFORM=mac
> ```

---

## Homelab bootstrap

For homelab (Mac Mini) setup, see the dedicated runbook at [profiles/homelab/mac/README.md](../profiles/homelab/mac/README.md).

---

Back to [README](../README.md)
