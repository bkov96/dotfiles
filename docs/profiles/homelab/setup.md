# 🏠 Homelab setup

Rebuild the homelab from a fresh Mac Mini to a headless server running all services. Written for and tested on an **M4 Mac Mini, macOS Tahoe 26.4.1**; system commands (`pmset`, `socketfilterfw`, `launchctl`, `sysadminctl`, `networksetup`) may behave differently on other versions.

| Phase | Where                         | User    | Result                                    |
| ----- | ----------------------------- | ------- | ----------------------------------------- |
| 1     | At a desk, with display       | `admin` | Headless-ready machine with an `ops` user |
| 2     | Permanent location, over SSH  | `ops`   | Tools installed, Wi-Fi off                |
| 3     | Over SSH + browser            | `ops`   | All services running and configured       |

## ✅ Prerequisites

- Fresh macOS install with an admin user created
- Apple ID, iCloud and Location Services disabled
- FileVault **off** (required for auto-login): System Settings → Privacy & Security → FileVault
- Display, keyboard and mouse connected for phase 1
- Wi-Fi on the same network as your work Mac
- A Bitwarden item and an SSH key pair, below

### Bitwarden item

Create a Secure Note named `dotfiles/homelab/mac` with these custom fields.

Needed for phase 1 (admin):

| Field                | Value                                         |
| -------------------- | --------------------------------------------- |
| `GIT_CONFIG_EMAIL`   | Git email                                     |
| `GIT_CONFIG_NAME`    | Git name                                      |
| `OPS_USER`           | Username for the ops account (e.g. `ops`)     |
| `OPS_PASSWORD`       | Password for the ops account                  |
| `SSH_PUBLIC_KEY_B64` | base64-encoded ed25519 public key (see below) |

Needed for phase 3 (services):

| Field                           | Value                                                    |
| ------------------------------- | -------------------------------------------------------- |
| `HOMELAB_IP`                    | Mac Mini static IP                                       |
| `LAB_DOMAIN`                    | Internal domain                                          |
| `SERVICES_DATA_DIR`             | Host path for persistent volumes                         |
| `MEDIA_ROOT`                    | Host path for the media library                          |
| `GRAFANA_ADMIN_PASSWORD`        | Initial Grafana admin password (see note)                |
| `TELEGRAM_BOT_TOKEN_MONITORING` | Token of the dedicated monitoring bot                    |
| `TELEGRAM_CHAT_ID_MONITORING`   | Chat ID that receives Grafana alerts                     |
| `QBITTORRENT_PASSWORD`          | qBittorrent admin password (used by its exporter)        |
| `RADARR_API_KEY`                | For Recyclarr and the exporter                           |
| `SONARR_API_KEY`                | For Recyclarr and the exporter                           |
| `PROWLARR_API_KEY`              | For the exporter                                         |
| `BAZARR_API_KEY`                | For the exporter                                         |
| `JELLYFIN_API_KEY`              | For the exporter                                         |
| `SEERR_API_KEY`                 | For the exporter                                         |

The Telegram values, passwords and API keys only exist once the services have run; phase 3 says when to fill each in.

> **`GRAFANA_ADMIN_PASSWORD`** is interpolated into a YAML Compose file by `envsubst`. Avoid YAML-special characters (`:`, `#`, `{`, `}`, `[`, `]`, `*`, `&`, `|`, `>`, `'`, `"`, `!`); stick to alphanumerics plus `-`, `_`, `@`.

### SSH key pair

On your work Mac (skip if `~/.ssh/id_ed25519_homelab` exists):

```sh
ssh-keygen -t ed25519 -C "homelab" -f ~/.ssh/id_ed25519_homelab
base64 -i ~/.ssh/id_ed25519_homelab.pub | tr -d '\n'
```

Save the output as `SSH_PUBLIC_KEY_B64`.

## 🖥 Phase 1: Admin bootstrap (at desk)

### 1.1 Clone

```sh
xcode-select --install
git clone https://github.com/bkov96/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles/profiles/homelab/mac
```

### 1.2 Initialize and install

```sh
make admin-init
make admin-install
```

Installs Homebrew, creates `.config.json` with `bw://` references, and installs all packages — including ops casks like OrbStack, because casks need admin privileges.

### 1.3 Configure the admin environment

```sh
make admin-configure
```

Links the admin `.zshrc` and unlocks Bitwarden (prompts for the master password). Then restart the shell or `source ~/.zshrc`.

### 1.4 Headless setup

```sh
make admin-headless-all
```

Or step by step:

```sh
make admin-headless-user             # Create ops user (non-admin)
make admin-headless-ssh              # Enable SSH, key-only auth, deploy keys
make admin-headless-energy           # Disable sleep, enable WoL + auto-restart
make admin-headless-firewall         # Enable firewall, allow SSH + VNC
make admin-headless-screen-sharing   # Enable Screen Sharing for ops
```

The scripts pause for two steps that can't be scripted on Tahoe:

- **Remote Login:** System Settings → General → Sharing → Remote Login → ON
- **Auto-login:** System Settings → Users & Groups → Automatic Login → select the ops user

### 1.5 Verify

```sh
make admin-verify
```

Prints a pass/fail summary and, if everything passes, offers to shut down for relocation.

### 1.6 Headless dry run (recommended)

Test before moving the machine:

1. Shut down the Mac Mini
2. Unplug display, keyboard and mouse (keep power and Wi-Fi)
3. Power on, wait ~60 seconds
4. From the work Mac: `ssh ops@<ip>`
5. Screen Sharing: Finder → Go → Connect to Server → `vnc://<ip>`

If anything fails, plug the display back in and fix it now.

## 🚚 Relocation

1. Power off and unplug everything
2. Move to the permanent location
3. Plug in **Ethernet and power only**
4. Power on — the machine auto-logs in as ops

## 🔌 Phase 2: Ops setup (over SSH)

```sh
ssh ops@<ip>
```

### 2.1 Clone and initialize

```sh
git clone https://github.com/bkov96/dotfiles.git ~/HomeLab/repos/dotfiles
cd ~/HomeLab/repos/dotfiles/profiles/homelab/mac
make ops-init
```

### 2.2 Install tools

```sh
make ops-install
```

Installs the remaining brew-only packages (casks came with `admin-install`).

### 2.3 Disable Wi-Fi

```sh
make ops-disable-wifi
```

Checks Ethernet connectivity first.

### 2.4 Verify

```sh
make ops-verify
```

### 2.5 Link the ops dotfiles

From the repo root:

```sh
cd ~/HomeLab/repos/dotfiles
export DOTFILES_PROFILE=homelab DOTFILES_PLATFORM=mac DOTFILES_USER=ops
make init
make packages-install
make configs-link
```

The ops `.zshrc` exports those three variables from now on, and `dfs` works everywhere.

## 🐳 Phase 3: Services

Background on how services work: [Services](services.md).

1. **Launch OrbStack once through the GUI** (`vnc://<ip>`) to finish its initial setup, and enable *Start at login*.
2. **Fill in the Bitwarden fields you can already know:** `HOMELAB_IP`, `LAB_DOMAIN`, `SERVICES_DATA_DIR`, `MEDIA_ROOT`, `GRAFANA_ADMIN_PASSWORD`.
3. **Create the Telegram monitoring bot** and store its token and chat ID — [Manual setup §7](manual-setup.md#7-telegram-monitoring-bot).
4. **Add the DNS records on the router** — [Manual setup §1](manual-setup.md#1-unifi-wildcard-dns-records).
5. **Start the native exporters** — [Manual setup §5–6](manual-setup.md#5-native-node_exporter).
6. **Start everything:**

   ```sh
   dfs configs unlock
   dfs services init
   dfs services start
   dfs services list
   ```

7. **Trust Caddy's root CA** on your devices — [Manual setup §2](manual-setup.md#2-trust-caddys-root-ca).
8. **Do the first-run logins:** Uptime Kuma, Portainer, Grafana, FileBrowser — [Manual setup §3–4, §8–9](manual-setup.md#3-uptime-kuma).
9. **Configure the media stack** in order — [Media: first-launch setup](media.md#-first-launch-setup). This produces the API keys.
10. **Store the API keys and start the exporters** — [Monitoring: exporters](monitoring.md#-exporters).
11. **Recreate the Uptime Kuma monitors** — [Monitoring: restore procedure](monitoring.md#restore-procedure).
12. **Confirm power-loss recovery** — [Manual setup §10](manual-setup.md#10-auto-recovery-after-power-loss).

## 🩺 Maintenance

| Need                    | Do                                                     |
| ----------------------- | ------------------------------------------------------ |
| sudo                    | `ssh admin@<ip>`                                       |
| GUI                     | Screen Sharing: `vnc://<ip>` (connects as ops)         |
| Machine not responding  | Check the router for its IP, try Wake on LAN           |
| Power loss              | Machine restarts and auto-logs in as ops on its own    |
