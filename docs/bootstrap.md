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
make install
```

Runs `brew bundle` to install all packages from the Brewfile, including the Bitwarden CLI.

## 5. Unlock Bitwarden

```sh
make unlock
```

This logs in to Bitwarden (if needed) and unlocks the vault, saving the session to `.bw_session` (gitignored). You only need to run this once per shell session.

For non-interactive environments (e.g. servers), set `BW_CLIENTID` and `BW_CLIENTSECRET` before running — `make unlock` will use API key auth automatically:

```sh
export BW_CLIENTID=user.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export BW_CLIENTSECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxx

make unlock
```

If you prefer not to use Bitwarden, set plain values directly in the `"env"` section of `.config.json` instead.

## 6. Link dotfiles

```sh
make link
```

That's it — your dotfiles are live. Your `.zshrc` now exports `DOTFILES_PROFILE` and `DOTFILES_PLATFORM` automatically, so you won't need to export them manually in future sessions.

> After `make link`, a `dotfiles` shell function is available in every new terminal. You can use it from anywhere instead of navigating to the repo:

> ```sh
> dotfiles link
> dotfiles gather DOTFILES_PROFILE=homelab DOTFILES_PLATFORM=mac
> ```

---

Back to [README](../README.md)
