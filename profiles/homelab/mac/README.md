# Homelab Mac Mini Bootstrap

## Contents

- [Prerequisites](#prerequisites)
- [Phase 1: Admin Bootstrap](#phase-1-admin-bootstrap-at-desk-with-display)
- [Relocation](#relocation)
- [Phase 2: Ops Setup](#phase-2-ops-setup-via-ssh-from-workmac)
- [Maintenance](#maintenance)
- [macOS version](#macos-version)

Bootstrap a fresh M4 Mac Mini (macOS Tahoe 26.4.1) into a headless homelab server.

## Prerequisites

- Fresh macOS Tahoe 26.4.1 install with an admin user created
- Apple ID, iCloud, Location Services, etc. disabled
- FileVault disabled (required for auto-login; System Settings > Privacy & Security > FileVault > Turn Off)
- Display, keyboard, and mouse connected (for initial setup)
- Wi-Fi connected to the same network as your work Mac
- Bitwarden account with a `dotfiles/homelab/mac` item (see below)
- SSH key pair generated on your work Mac (see below)

### Bitwarden setup

Create a Bitwarden item named `dotfiles/homelab/mac` (e.g., a Secure Note) with these custom fields:

| Field                | Value                                         |
| -------------------- | --------------------------------------------- |
| `GIT_CONFIG_EMAIL`   | email for the admin account                   |
| `GIT_CONFIG_NAME`    | name for the admin account                    |
| `OPS_USER`           | username for the ops account (e.g., `ops`)    |
| `OPS_PASSWORD`       | password for the ops account                  |
| `SSH_PUBLIC_KEY_B64` | base64-encoded ed25519 public key (see below) |

### SSH key pair

Generate a dedicated key pair on your **work or personal Mac** (if not already done):

    ssh-keygen -t ed25519 -C "homelab" -f ~/.ssh/id_ed25519_homelab

Base64-encode the public key for Bitwarden:

    base64 -i ~/.ssh/id_ed25519_homelab.pub | tr -d '\n'

Copy the output and save it as the `SSH_PUBLIC_KEY_B64` field in the Bitwarden item above.

## Phase 1: Admin Bootstrap (at desk, with display)

### 1.1 Pre-bootstrap

Install Xcode Command Line Tools (needed for `git`):

    xcode-select --install

Clone this repo:

    git clone https://github.com/bkov96/dotfiles.git ~/repos/dotfiles
    cd ~/repos/dotfiles/profiles/homelab/mac

### 1.2 Initialize and install

    make admin-init
    make admin-install

This installs Homebrew, creates `.config.json` with `bw://` references, and installs all Homebrew packages (admin tools + ops casks like OrbStack). Cask packages require admin privileges, so they are installed during the admin phase.

### 1.3 Configure admin environment

    make admin-configure

This links the admin `.zshrc` (gives you the `dotfiles` shell function) and unlocks the Bitwarden vault. You'll be prompted for your Bitwarden master password.

After this step, restart your shell (or `source ~/.zshrc`) so the `dotfiles` function is available.

### 1.4 Headless setup

Run all headless configuration at once:

    make admin-headless-all

Or run individual steps:

    make admin-headless-user             # Create ops user (non-admin)
    make admin-headless-ssh              # Enable SSH, key-only auth, deploy keys
    make admin-headless-energy           # Disable sleep, enable WoL + auto-restart
    make admin-headless-firewall         # Enable firewall, allow SSH + VNC
    make admin-headless-screen-sharing   # Enable Screen Sharing for ops

The scripts will pause and prompt you for manual steps that can't be scripted on macOS Tahoe:

- **Remote Login**: System Settings > General > Sharing > Remote Login > toggle ON
- **Auto-login for ops**: System Settings > Users & Groups > Automatic Login > select ops user

### 1.5 Verify

    make admin-verify

This runs all verification checks and prints a pass/fail summary. If everything passes, it offers to shut down the machine for relocation.

### 1.6 Headless dry run (recommended)

Before relocating, test headless mode at your desk:

1. Shut down the Mac Mini
2. Unplug display, keyboard, and mouse (keep power + Wi-Fi)
3. Power on and wait ~60 seconds
4. From your work Mac: `ssh ops@<ip>`
5. Try Screen Sharing from Finder > Go > Connect to Server > `vnc://<ip>`

If anything fails, plug the display back in and fix it. That's the whole point of testing here.

## Relocation

1. Power off the Mac Mini
2. Unplug everything
3. Move to permanent location
4. Plug in Ethernet and power only
5. Power on — machine auto-logs in as ops

## Phase 2: Ops Setup (via SSH from work/mac)

SSH into the Mac Mini:

    ssh ops@<ip>

### 2.1 Clone and initialize

    git clone https://github.com/bkov96/dotfiles.git ~/repos/dotfiles
    cd ~/repos/dotfiles/profiles/homelab/mac
    make ops-init

### 2.2 Install tools

Cask packages (OrbStack, etc.) were already installed by `make admin-install`. This step installs any remaining brew-only packages:

    make ops-install

### 2.3 Disable Wi-Fi

    make ops-disable-wifi

This verifies Ethernet connectivity before disabling Wi-Fi.

### 2.4 Verify

    make ops-verify

### 2.5 Standard dotfiles workflow

After bootstrap, the ops `.zshrc` exports `DOTFILES_PROFILE=homelab`, `DOTFILES_PLATFORM=mac`, and `DOTFILES_USER=ops`. Use the standard `dotfiles` commands in the directory root:

    make init
    make packages-install
    make configs-link

## Maintenance

- **Need sudo?** SSH in as admin: `ssh admin@<ip>`
- **Need GUI?** Screen Sharing: `vnc://<ip>` (connects as ops)
- **Machine not responding?** Check router for IP, try Wake on LAN
- **Power loss?** Machine auto-restarts and auto-logs in as ops

## macOS version

These scripts were written for and tested on **macOS Tahoe 26.4.1**. System commands (`pmset`, `socketfilterfw`, `launchctl`, `sysadminctl`, `networksetup`) may behave differently on other versions.
